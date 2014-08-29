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

require 'webmock/rspec'
require 'snowplow-tracker'

require 'coveralls'
Coveralls.wear!

WebMock.disable_net_connect!(:allow_localhost => true)

RSpec.configure do |config|
  config.before(:each) do
    stub_request(:any, /localhost/).
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => [200], :body => 'stubbed response')
    stub_request(:any, /nonexistent/).
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => [404], :body => 'stubbed response')
  end
end

module SnowplowTracker
  class Emitter

    # Event querystrings will be added here
    @@querystrings = ['']

    old_http_get = instance_method(:http_get)

    define_method(:http_get) do |payload|

      # This additional line records event querystrings
      @@querystrings.push(URI(@collector_uri + '?' + URI.encode_www_form(payload)).query)

      old_http_get.bind(self).(payload)
    end

    # New method to get the n-th from last querystring
    def get_last_querystring(n=1)
      return @@querystrings[-n]
    end

  end
end
