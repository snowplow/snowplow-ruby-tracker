# Copyright (c) 2013-2014 Snowplow Analytics Ltd. All rights reserved.
#
# This program is licensed to you under the Apache License Version 2.0,
# and you may not use this file except in compliance with the Apache License Version 2.0.
# You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the Apache License Version 2.0 is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.

# Author:: Alex Dean, Fred Blundun (mailto:support@snowplowanalytics.com)
# Copyright:: Copyright (c) 2013-2014 Snowplow Analytics Ltd
# License:: Apache License Version 2.0

require 'net/https'
require 'set'
require 'logger'
require 'contracts'

module SnowplowTracker
  LOGGER = Logger.new(STDERR)
  LOGGER.level = Logger::INFO

  class Emitter
    include Contracts

    CONFIG_HASH = {
      protocol: Maybe[Or['http', 'https']],
      port: Maybe[Num],
      method: Maybe[Or['get', 'post']],
      buffer_size: Maybe[Num],
      on_success: Maybe[Func[Num => Any]],
      on_failure: Maybe[Func[Num, Hash => Any]],
      thread_count: Maybe[Num],
      logger: Maybe[Logger]
    }

    STRICT_CONFIG_HASH = And[CONFIG_HASH, ->(x) {
      (x.class == Hash) && Set.new(x.keys).subset?(Set.new(CONFIG_HASH.keys))
    }]

    DEFAULT_CONFIG = {
      protocol: 'http',
      method: 'get'
    }

    attr_reader :logger

    Contract String, STRICT_CONFIG_HASH => Any
    def initialize(endpoint, start_config = {})
      config = DEFAULT_CONFIG.merge(start_config)
      @lock = Monitor.new
      @collector_uri = as_collector_uri(endpoint, config[:protocol], config[:port], config[:method])
      @buffer = []
      @buffer_size = confirm_buffer_size(config)
      @method = config[:method]
      @on_success = config[:on_success]
      @on_failure = config[:on_failure]
      @logger = config[:logger] || LOGGER
      logger.info("#{self.class} initialized with endpoint #{@collector_uri}")
    end

    Contract Hash => Num
    def confirm_buffer_size(config)
      return config[:buffer_size] unless config[:buffer_size].nil?

      config[:method] == 'get' ? 1 : 10
    end

    # Build the collector URI from the configuration hash
    #
    Contract String, String, Maybe[Num], String => String
    def as_collector_uri(endpoint, protocol, port, method)
      port_string = port.nil? ? '' : ":#{port}"
      path = method == 'get' ? '/i' : '/com.snowplowanalytics.snowplow/tp2'

      "#{protocol}://#{endpoint}#{port_string}#{path}"
    end

    # Add an event to the buffer and flush it if maximum size has been reached
    # Part of the public API
    #
    Contract Hash => nil
    def input(payload)
      payload.each { |k, v| payload[k] = v.to_s }
      @lock.synchronize do
        @buffer.push(payload)
        flush if @buffer.size >= @buffer_size
      end

      nil
    end

    # Flush the buffer
    #
    Contract Bool => nil
    def flush(_async = true)
      @lock.synchronize do
        send_requests(@buffer)
        @buffer = []
      end

      nil
    end

    # Send all events in the buffer to the collector
    #
    Contract ArrayOf[Hash] => nil
    def send_requests(events)
      if events.empty?
        logger.info('Skipping sending events since buffer is empty')
        return
      end

      logger.info("Attempting to send #{events.size} request#{events.size == 1 ? '' : 's'}")

      events.each do |event|
        # add the sent timestamp, overwrite if already exists
        event['stm'] = Timestamp.create.to_s
      end

      if @method == 'post'
        send_requests_with_post(events)
      elsif @method == 'get'
        send_requests_with_get(events)
      end

      nil
    end

    Contract ArrayOf[Hash] => nil
    def send_requests_with_post(events)
      post_succeeded = false
      begin
        request = http_post(SelfDescribingJson.new(
          'iglu:com.snowplowanalytics.snowplow/payload_data/jsonschema/1-0-4',
          events
        ).to_json)
        post_succeeded = good_status_code?(request.code)
      rescue StandardError => standard_error
        logger.warn(standard_error)
      end

      if post_succeeded
        @on_success.call(events.size) unless @on_success.nil?
      else
        @on_failure.call(0, events) unless @on_failure.nil?
      end

      nil
    end

    Contract ArrayOf[Hash] => nil
    def send_requests_with_get(events)
      success_count = 0
      unsent_requests = []

      events.each do |event|
        request = process_get_event(event)
        request ? success_count += 1 : unsent_requests << event
      end

      if unsent_requests.size.zero?
        @on_success.call(success_count) unless @on_success.nil?
      else
        @on_failure.call(success_count, unsent_requests) unless @on_failure.nil?
      end

      nil
    end

    Contract Hash => Bool
    def process_get_event(event)
      get_succeeded = false
      begin
        request = http_get(event)
        get_succeeded = good_status_code?(request.code)
      rescue StandardError => standard_error
        logger.warn(standard_error)
      end
      get_succeeded
    end

    # Send a GET request
    #
    Contract Hash => ->(x) { x.is_a? Net::HTTPResponse }
    def http_get(payload)
      destination = URI(@collector_uri + '?' + URI.encode_www_form(payload))
      logger.info("Sending GET request to #{@collector_uri}...")
      logger.debug("Payload: #{payload}")
      http = Net::HTTP.new(destination.host, destination.port)
      request = Net::HTTP::Get.new(destination.request_uri)
      http.use_ssl = true if destination.scheme == 'https'
      response = http.request(request)
      logger.add(good_status_code?(response.code) ? Logger::INFO : Logger::WARN) do
        "GET request to #{@collector_uri} finished with status code #{response.code}"
      end

      response
    end

    # Send a POST request
    #
    Contract Hash => ->(x) { x.is_a? Net::HTTPResponse }
    def http_post(payload)
      logger.info("Sending POST request to #{@collector_uri}...")
      logger.debug("Payload: #{payload}")
      destination = URI(@collector_uri)
      http = Net::HTTP.new(destination.host, destination.port)
      request = Net::HTTP::Post.new(destination.request_uri)
      http.use_ssl = true if destination.scheme == 'https'
      request.body = payload.to_json
      request.set_content_type('application/json; charset=utf-8')
      response = http.request(request)
      logger.add(good_status_code?(response.code) ? Logger::INFO : Logger::WARN) do
        "POST request to #{@collector_uri} finished with status code #{response.code}"
      end

      response
    end

    # Only 2xx and 3xx status codes are considered successes
    #
    Contract String => Bool
    def good_status_code?(status_code)
      status_code.to_i >= 200 && status_code.to_i < 400
    end

    private :as_collector_uri,
            :http_get,
            :http_post
  end

  class AsyncEmitter < Emitter
    Contract String, STRICT_CONFIG_HASH => Any
    def initialize(endpoint, config = {})
      @queue = Queue.new
      # @all_processed_condition and @results_unprocessed are used to emulate Python's Queue.task_done()
      @queue.extend(MonitorMixin)
      @all_processed_condition = @queue.new_cond
      @results_unprocessed = 0
      (config[:thread_count] || 1).times { Thread.new { consume } }
      super(endpoint, config)
    end

    def consume
      loop do
        work_unit = @queue.pop
        send_requests(work_unit)
        @queue.synchronize do
          @results_unprocessed -= 1
          @all_processed_condition.broadcast
        end
      end
    end

    # Flush the buffer
    # If async is false, block until the queue is empty
    #
    def flush(async = true)
      loop do
        @lock.synchronize do
          @queue.synchronize { @results_unprocessed += 1 }
          @queue << @buffer
          @buffer = []
        end
        unless async
          logger.info('Starting synchronous flush')
          @queue.synchronize do
            @all_processed_condition.wait_while { @results_unprocessed > 0 }
            logger.info('Finished synchronous flush')
          end
        end
        break if @buffer.empty?
      end
    end
  end
end
