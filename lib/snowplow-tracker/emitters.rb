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
  # @see Emitter
  # For logging Emitter activity messages
  LOGGER = Logger.new(STDERR)
  LOGGER.level = Logger::INFO

  # This class sends events to the event collector. All {Tracker}s must have at
  # least one associated Emitter or the subclass AsyncEmitter.
  #
  # The network settings are defined as part of the Emitter initalization. This
  # table displays the default Emitter settings:
  #
  # | Property | Default setting |
  # | --- | --- |
  # | Protocol | HTTP |
  # | Method | GET |
  # | Buffer size | 1 |
  # | Path | `/i` |
  #
  # The buffer size is 1 because GET requests can only contain one event.
  #
  # If you choose to use POST requests, the buffer_size defaults to 10, and the
  # buffered events are all sent together in a single request. The default path
  # is '/com.snowplowanalytics.snowplow/tp2' for Emitters using POST.
  #
  # # Logging
  # Emitters log their activity to STDERR by default, using the Ruby standard
  # library Logger class. A different logger can be configured during Emitter
  # initialization. For example, to disable logging, you could provide
  # `Logger.new(IO::NULL)` in the options hash.
  #
  # By default, only messages with priority "INFO" or higher will be logged.
  # This can be changed at any time for the default logger, which is saved as a
  # module constant (`LOGGER = Logger.new(STDERR)`). If you are not using the
  # default logger, set the message level before initializing your Emitter.
  #
  # @see https://ruby-doc.org/stdlib-2.7.2/libdoc/logger/rdoc/Logger.html Logger documentation
  #
  # @example Changing the logger message level.
  #   require 'logger'
  #   SnowplowTracker::LOGGER.level = Logger::DEBUG
  class Emitter
    include Contracts

    # Contract types

    # @private
    CONFIG_HASH = {
      path: Maybe[String],
      protocol: Maybe[Or['http', 'https']],
      port: Maybe[Num],
      method: Maybe[Or['get', 'post']],
      buffer_size: Maybe[Num],
      on_success: Maybe[Func[Num => Any]],
      on_failure: Maybe[Func[Num, Hash => Any]],
      thread_count: Maybe[Num],
      logger: Maybe[Logger]
    }

    # @private
    STRICT_CONFIG_HASH = And[CONFIG_HASH, ->(x) {
                                            (x.class == Hash) && Set.new(x.keys).subset?(Set.new(CONFIG_HASH.keys))
                                          }]

    # @!group Public constants

    # Default Emitter settings
    DEFAULT_CONFIG = {
      protocol: 'http',
      method: 'get'
    }

    # @!endgroup

    # @private
    attr_reader :logger

    Contract KeywordArgs[endpoint: String, options: Optional[STRICT_CONFIG_HASH]] => Any
    # Create a new Emitter instance. The endpoint is required.
    #
    # @example Initializing an Emitter with all the possible extra configuration.
    #   success_callback = ->(success_count) { puts "#{success_count} events sent successfully" }
    #   failure_callback = ->(success_count, failures) do
    #     puts "#{success_count} events sent successfully, #{failures.size} sent unsuccessfully"
    #   end
    #
    #   Emitter.new(endpoint: 'collector.example.com',
    #               options: { path: '/my-pipeline/1',
    #                          protocol: 'https',
    #                          port: 443,
    #                          method: 'post',
    #                          buffer_size: 5,
    #                          on_success: success_callback,
    #                          on_failure: failure_callback,
    #                          logger: Logger.new(STDOUT) })
    #
    # The options hash can have any of these optional parameters:
    #
    # | Parameter | Description | Type |
    # | --- | --- | --- |
    # | path | Override the default path for appending to the endpoint | String |
    # | protocol | 'http' or 'https' | String |
    # | port | The port for the connection | Integer |
    # | method | 'get' or 'post' | String |
    # | buffer_size | Number of events to send at once | Integer |
    # | on_success | A function to call if events were sent successfully | Function |
    # | on_failure | A function to call if events did not send | Function |
    # | thread_count | Number of threads to use | Integer |
    # | logger | Log somewhere other than STDERR | Logger |
    #
    # Note that `thread_count` is relevant only to the subclass {AsyncEmitter},
    # and will be ignored if provided to an Emitter.
    #
    # If you choose to use HTTPS, we recommend using port 443.
    #
    # @param endpoint [String] the endpoint to send the events to
    # @param options [Hash] allowed configuration options
    #
    # @see AsyncEmitter#initialize
    # @api public
    def initialize(endpoint:, options: {})
      config = DEFAULT_CONFIG.merge(options)
      @lock = Monitor.new
      path = confirm_path(config)
      @collector_uri = create_collector_uri(endpoint, config[:protocol], config[:port], path)
      @buffer = []
      @buffer_size = confirm_buffer_size(config)
      @method = config[:method]
      @on_success = config[:on_success]
      @on_failure = config[:on_failure]
      @logger = config[:logger] || LOGGER
      logger.info("#{self.class} initialized with endpoint #{@collector_uri}")
    end

    Contract Hash => Num
    # Creates the `@buffer_size` variable during initialization. Unless
    # otherwise defined, it's 1 for Emitters using GET and 10 for Emitters using
    # POST requests.
    # @private
    def confirm_buffer_size(config)
      return config[:buffer_size] unless config[:buffer_size].nil?

      config[:method] == 'get' ? 1 : 10
    end

    Contract Hash => String
    # Creates the `@path` variable during initialization. Allows a non-standard
    # path to be provided.
    # @private
    def confirm_path(config)
      return config[:path] unless config[:path].nil?

      config[:method] == 'get' ? '/i' : '/com.snowplowanalytics.snowplow/tp2'
    end

    # Build the collector URI from the configuration hash
    #
    Contract String, String, Maybe[Num], String => String
    # Creates the `@collector_uri` variable during initialization.
    # The default is "http://{endpoint}/i".
    # @private
    def create_collector_uri(endpoint, protocol, port, path)
      port_string = port.nil? ? '' : ":#{port}"

      "#{protocol}://#{endpoint}#{port_string}#{path}"
    end

    Contract Hash => nil
    # Add an event to the buffer and flush it if maximum size has been reached.
    # This method is not required for standard Ruby tracker usage. A {Tracker}
    # privately calls this method once the event payload is ready to send.
    #
    # We have included it as part of the public API for its possible use in the
    # `on_failure` callback. This is the optional method, provided in the
    # `options` Emitter initalization hash, that is called when events fail
    # to send. You could use {#input} as part of your callback to immediately
    # retry the failed event.
    #
    # @example A possible `on_failure` method using `#input`
    #   def retry_on_failure(failed_event_count, failed_events)
    #     # possible backoff-and-retry timeout here
    #     failed_events.each do |event|
    #       my_emitter.input(event)
    #     end
    #   end
    #
    # @api public
    def input(payload)
      payload.each { |k, v| payload[k] = v.to_s }
      @lock.synchronize do
        @buffer.push(payload)
        flush if @buffer.size >= @buffer_size
      end

      nil
    end

    Contract Bool => nil
    # Flush the Emitter, forcing it to send all the events in its
    # buffer, even if the buffer is not full. {Emitter} objects, unlike
    # {AsyncEmitter}s, can only `flush` synchronously. A {Tracker} can manually flush all
    # its Emitters by calling {Tracker#flush}, part of the public API which
    # calls this method.
    #
    # The unused async parameter here is to avoid ArgumentError, since
    # {AsyncEmitter#flush} does take an argument.
    #
    # @see AsyncEmitter#flush
    # @private
    def flush(_async = true)
      @lock.synchronize do
        send_requests(@buffer)
        @buffer = []
      end

      nil
    end

    Contract ArrayOf[Hash] => nil
    # Send all events in the buffer to the collector
    # @private
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
    # Part of {#send_requests}.
    # @private
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
    # Part of {#send_requests}.
    # @private
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
    # Part of {#send_requests_with_get}.
    # @private
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

    Contract Hash => ->(x) { x.is_a? Net::HTTPResponse }
    # Part of {#process_get_event}. This sends a GET request.
    # @private
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

    Contract Hash => ->(x) { x.is_a? Net::HTTPResponse }
    # Part of {#send_requests_with_post}. This sends a POST request.
    # @private
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

    Contract String => Bool
    # Check if the response is good.
    # Only 2xx and 3xx status codes are considered successes.
    # @private
    def good_status_code?(status_code)
      status_code.to_i >= 200 && status_code.to_i < 400
    end

    private :create_collector_uri,
            :http_get,
            :http_post
  end

  # This {Emitter} subclass provides asynchronous event sending. Whenever the
  # buffer is flushed, the AsyncEmitter places the flushed events in a work
  # queue. The AsyncEmitter asynchronously sends events in this queue using a
  # thread pool of a fixed size. The size of the thread pool is 1 by default,
  # but can be configured as part of the options hash during initialization.
  #
  # @see Emitter
  # @api public
  class AsyncEmitter < Emitter
    Contract KeywordArgs[endpoint: String, options: Optional[STRICT_CONFIG_HASH]] => Any
    # Create a new AsyncEmitter object. The endpoint is required.
    #
    # @example Initializing an AsyncEmitter with all the possible extra configuration.
    #   success_callback = ->(success_count) { puts "#{success_count} events sent successfully" }
    #   failure_callback = ->(success_count, failures) do
    #     puts "#{success_count} events sent successfully, #{failures.size} sent unsuccessfully"
    #   end
    #
    #   Emitter.new(endpoint: 'collector.example.com',
    #               options: { path: '/my-pipeline/1',
    #                          protocol: 'https',
    #                          port: 443,
    #                          method: 'post',
    #                          buffer_size: 5,
    #                          on_success: success_callback,
    #                          on_failure: failure_callback,
    #                          logger: Logger.new(STDOUT),
    #                          thread_count: 5 })
    #
    # The options hash can have any of these optional parameters:
    #
    # | Parameter | Description | Type |
    # | --- | --- | --- |
    # | path | Override the default path for appending to the endpoint | String |
    # | protocol | 'http' or 'https' | String |
    # | port | The port for the connection | Integer |
    # | method | 'get' or 'post' | String |
    # | buffer_size | Number of events to send at once | Integer |
    # | on_success | A function to call if events were sent successfully | Function |
    # | on_failure | A function to call if events did not send | Function |
    # | thread_count | Number of threads to use | Integer |
    # | logger | Log somewhere other than STDERR | Logger |
    #
    # The `thread_count` determines the number of worker threads which will be
    # used to send events.
    #
    # If you choose to use HTTPS, we recommend using port 443.
    #
    # @note if you test the AsyncEmitter by using a short script to send an
    #   event, you may find that the event fails to send. This is because the
    #   process exits before the flushing thread is finished. You can get round
    #   this either by adding a sleep(10) to the end of your script or by using
    #   the synchronous flush.
    #
    # @param endpoint [String] the endpoint to send the events to
    # @param options [Hash] allowed configuration options
    #
    # @see Emitter#initialize
    # @api public
    def initialize(endpoint:, options: {})
      @queue = Queue.new
      # @all_processed_condition and @results_unprocessed are used to emulate Python's Queue.task_done()
      @queue.extend(MonitorMixin)
      @all_processed_condition = @queue.new_cond
      @results_unprocessed = 0
      (options[:thread_count] || 1).times { Thread.new { consume } }
      super(endpoint: endpoint, options: options)
    end

    # AsyncEmitters use the MonitorMixin module, which provides the
    # `synchronize` and `broadcast` methods.
    # @private
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

    # Flush the Emitter, forcing it to send all the events in its buffer, even
    # if the buffer is not full.
    #
    # If `async` is true (the default), events are sent even if the queue is not
    # empty. If `async` is false, it blocks until all queued events have been
    # sent. Note that this method can be called by public API method
    # {Tracker#flush}, which has a default of `async` being false.
    #
    # @param async [Bool] whether to flush asynchronously or not
    #
    # @see Emitter#flush
    # @private
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
