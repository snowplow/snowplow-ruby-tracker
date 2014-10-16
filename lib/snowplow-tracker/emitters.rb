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

require 'net/http'
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
      :on_failure => Maybe[Func[Num, Hash => Any]]
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
      @threads = []
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
      @buffer.push(payload)
      if @buffer.size > @buffer_size
        flush
      end

      nil
    end

    # Flush the buffer
    #
    Contract Bool => nil
    def flush(sync=false)
      send_requests

      nil
    end

    # Send all events in the buffer to the collector
    #
    Contract None => nil
    def send_requests
      LOGGER.info("Attempting to send #{@buffer.size} request#{@buffer.size == 1 ? '' : 's'}")
      temp_buffer = @buffer
      @buffer = []

      if @method == 'get'
        success_count = 0
        unsent_requests = []
        temp_buffer.each do |payload|
          request = http_get(payload)
          if request.code.to_i == 200
            success_count += 1
          else
            unsent_requests.push(payload)
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

      elsif @method == 'post'
        if temp_buffer.size > 0
          request = http_post({
            'schema' => 'iglu:com.snowplowanalytics.snowplow/payload_data/1-0-1',
            'data' => temp_buffer
          })

          if request.code.to_i == 200
            unless @on_success.nil?
              @on_success.call(temp_buffer.size)
            end
          else
            unless @on_failure.nil?
              @on_failure.call(0, temp_buffer)
            end
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
      response = Net::HTTP.get_response(destination)
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
      request = Net::HTTP::Post.new(destination)
      request.form_data = payload
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

    # Flush the buffer in a new thread
    #  If sync is true, block until all flushing threads have exited
    #
    def flush(sync=false)
      t = Thread.new do
        send_requests
      end
      t.abort_on_exception = true
      @threads.select!{ |thread| thread.alive?}
      @threads.push(t)

      if sync
        LOGGER.info('Starting synchronous flush')
        @threads.each do |thread|
          thread.join(10)
        end
      end

      nil
    end

  end

end
