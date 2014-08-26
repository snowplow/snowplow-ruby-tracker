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
require 'contracts'
include Contracts

module SnowplowTracker

  class Emitter

    #Contract nil => Emitter
    def initialize(endpoint, protocol='http', port=nil, method='get', buffer_size=nil, on_success=nil, on_failure=nil)
      @collector_uri = as_collector_uri(endpoint, protocol, port, method)
      @buffer = []
      if not buffer_size.nil?
        @buffer_size = buffer_size
      elsif method == 'get'
        @buffer_size = 0
      else
        @buffer_size = 10
      end
      @method = method
      @on_success = on_success
      @on_failure = on_failure
      @threads = []

      self
    end

    def as_collector_uri(endpoint, protocol, port, method)
      port_string = port == nil ? '' : ":#{port.to_s}"
      path = method == 'get' ? '/i' : '/com.snowplowanalytics.snowplow/tp2'

      "#{protocol}://#{endpoint}#{port_string}#{path}"
    end

    def input(payload)
      payload.each { |k,v| payload[k] = v.to_s}
      @buffer.push(payload)
      if @buffer.size > @buffer_size
        flush
      end
    end

    def flush(sync=false)
      send_requests
    end

    def send_requests
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
            'schema' => 'iglu:com.snowplowanalytics.snowplow/payload_data/1-0-0',
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

    end

    def http_get(payload)
      destination = URI(@collector_uri + '?' + URI.encode_www_form(payload))
      Net::HTTP.get_response(destination)
    end

    def http_post(payload)
      destination = URI(@collector_uri)
      Net::HTTP.post_form(destination, payload)
    end

    private :as_collector_uri,
            :http_get,
            :http_post

  end


  class AsyncEmitter < Emitter

    def flush(sync=false)
      t = Thread.new do
        send_requests
      end
      t.abort_on_exception = true
      @threads.select!{ |thread| thread.alive?}
      @threads.push(t)

      if sync
        @threads.each(&:join)
      end

    end

  end

end
