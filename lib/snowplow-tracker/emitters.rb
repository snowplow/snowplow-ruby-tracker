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
include Contracts

module SnowplowTracker

  LOGGER = Logger.new(STDERR)
  LOGGER.level = Logger::INFO

  class Emitter

    @@ConfigHash = ({
      :protocol => Maybe[Or['http', 'https']],
      :port => Maybe[Num],
      :method => Maybe[Or['get', 'post']],
      :buffer_size => Maybe[Num],
      :on_success => Maybe[Func[Num => Any]],
      :on_failure => Maybe[Func[Num, Hash => Any]],
      :thread_count => Maybe[Num]
    })

    @@StrictConfigHash = And[@@ConfigHash, lambda { |x|
      x.class == Hash and Set.new(x.keys).subset? Set.new(@@ConfigHash.keys)
    }]

    @@DefaultConfig = {
      :protocol => 'http',
      :method => 'get'
    }

    Contract String, @@StrictConfigHash => lambda { |x| x.is_a? Emitter }
    def initialize(endpoint, config={})
      config = @@DefaultConfig.merge(config)
      @lock = Monitor.new
      @collector_uri = as_collector_uri(endpoint, config[:protocol], config[:port], config[:method])
      @buffer = []
      if not config[:buffer_size].nil?
        @buffer_size = config[:buffer_size]
      elsif config[:method] == 'get'
        @buffer_size = 0
      else
        @buffer_size = 10
      end
      @method = config[:method]
      @on_success = config[:on_success]
      @on_failure = config[:on_failure]
      LOGGER.info("#{self.class} initialized with endpoint #{@collector_uri}")

      self
    end

    # Build the collector URI from the configuration hash
    #
    Contract String, String, Maybe[Num], String => String
    def as_collector_uri(endpoint, protocol, port, method)
      port_string = port == nil ? '' : ":#{port.to_s}"
      path = method == 'get' ? '/i' : '/com.snowplowanalytics.snowplow/tp2'

      "#{protocol}://#{endpoint}#{port_string}#{path}"
    end

    # Add an event to the buffer and flush it if maximum size has been reached
    #
    Contract Hash => nil
    def input(payload)
      payload.each { |k,v| payload[k] = v.to_s}
      @lock.synchronize do
        @buffer.push(payload)
        if @buffer.size > @buffer_size
          flush
        end
      end

      nil
    end

    # Flush the buffer
    #
    Contract Bool => nil
    def flush(sync=false)
      @lock.synchronize do
        send_requests(@buffer)
        @buffer = []
      end
      nil
    end

    # Send all events in the buffer to the collector
    #
    Contract ArrayOf[Hash] => nil
    def send_requests(evts)
      LOGGER.info("Attempting to send #{@buffer.size} request#{@buffer.size == 1 ? '' : 's'}")


      if @method == 'post'
        request = http_post({
          'schema' => 'iglu:com.snowplowanalytics.snowplow/payload_data/jsonschema/1-0-2',
          'data' => evts
        })
        if request.code.to_i == 200
          unless @on_success.nil?
            @on_success.call(evts.size)
          end
        else
          unless @on_failure.nil?
            @on_failure.call(0, evts)
          end
        end

      elsif @method == 'get'
        success_count = 0
        unsent_requests = []
        evts.each do |evt|
          request = http_get(evt)
          get_succeeded = request.code.to_i == 200
          if get_succeeded
            success_count += 1
          else
            unsent_requests << evt
          end
        end
        if unsent_requests.size == 0
          unless @on_success.nil?
            @on_success.call(success_count)
          end
        else
          unless @on_failure.nil?
            @on_failure.call(success_count, unsent_requests)
          end
        end
      end

      nil
    end

    # Send a GET request
    #
    Contract Hash => lambda { |x| x.is_a? Net::HTTPResponse }
    def http_get(payload)
      destination = URI(@collector_uri + '?' + URI.encode_www_form(payload))
      LOGGER.info("Sending GET request to #{@collector_uri}...")
      LOGGER.debug("Payload: #{payload}")
      http = Net::HTTP.new(destination.host, destination.port)
      request = Net::HTTP::Get.new(destination.request_uri)
      if destination.scheme == 'https'
        http.use_ssl = true
      end
      response = http.request(request)
      LOGGER.add(response.code == '200' ? Logger::INFO : Logger::WARN) {
        "GET request to #{@collector_uri} finished with status code #{response.code}"
      }

      response
    end

    # Send a POST request
    #
    Contract Hash => lambda { |x| x.is_a? Net::HTTPResponse }
    def http_post(payload)
      LOGGER.info("Sending POST request to #{@collector_uri}...")
      LOGGER.debug("Payload: #{payload}")
      destination = URI(@collector_uri)
      http = Net::HTTP.new(destination.host, destination.port)
      request = Net::HTTP::Post.new(destination.request_uri)
      if destination.scheme == 'https'
        http.use_ssl = true
      end
      request.body = payload.to_json
      request.set_content_type('application/json; charset=utf-8')
      response = http.request(request)
      LOGGER.add(response.code == '200' ? Logger::INFO : Logger::WARN) {
        "POST request to #{@collector_uri} finished with status code #{response.code}"
      }

      response
    end

    private :as_collector_uri,
            :http_get,
            :http_post

  end


  class AsyncEmitter < Emitter

    Contract String, @@StrictConfigHash => lambda { |x| x.is_a? Emitter }
    def initialize(endpoint, config={})
      @queue = Queue.new()
      # @all_processed_condition and @results_unprocessed are used to emulate Python's Queue.task_done()
      @queue.extend(MonitorMixin)
      @all_processed_condition = @queue.new_cond
      @results_unprocessed = 0
      (config[:thread_count] || 1).times do
        t = Thread.new do
          consume
        end
      end
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
    #  If sync is true, block until the queue is empty
    #
    def flush(sync=false)
      @lock.synchronize do
        @queue.synchronize do
          @results_unprocessed += 1
        end
        @queue << @buffer
        @buffer = []
      end
      if sync
        LOGGER.info('Starting synchronous flush')
        @queue.synchronize do
          @all_processed_condition.wait_while { @results_unprocessed > 0 }
          LOGGER.info('Finished synchronous flush')
        end
      end
    end
  end

end
