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
    def initialize(endpoint, protocol='http', port=nil, method='get', buffer_size=nil)
      @collector_uri = as_collector_uri(endpoint, protocol, port, method)
      @buffer = []
      @buffer_size = 0
      @method = method
      self
    end

    def as_collector_uri(endpoint, protocol, port, method)
      port_string = port == nil ? '' : port.to_s + ':'
      path = method == 'get' ? '/i' : '/com.snowplowanalytics.snowplow/tp2'

      protocol + '://' + endpoint + port_string + path
    end

    def input(payload)
      @buffer.push(payload)
      if @buffer.size > @buffer_size
        flush
      end
    end

    def flush
      temp_buffer = @buffer
      @buffer = []
      if @method == 'get'
        temp_buffer.each do |payload|
          http_get(payload)
        end
      elsif @method == 'post'
        if temp_buffer.size > 0
          http_post({
            'schema' => 'iglu:com.snowplowanalytics.snowplow/payload_data/1-0-0',
            'data' => temp_buffer
          })
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

  x = Emitter.new('d3rkrsqld9gmqf.cloudfront.net')
  x.input({})
end
