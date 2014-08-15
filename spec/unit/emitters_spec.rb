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

require 'spec_helper'
require 'cgi'

describe SnowplowTracker::Emitter, 'Sending requests' do

  it 'sends a payload' do
    emitter = SnowplowTracker::Emitter.new('localhost')
    emitter.input({'key' => 'value'})
    param_hash = CGI.parse(emitter.get_last_querystring)
    expected_fields = {
      'key' => 'value'}
    for pair in expected_fields
      expect(param_hash[pair[0]][0]).to eq(pair[1])
    end
  end

  it 'executes a callback on success' do
    callback_executed = false
    emitter = SnowplowTracker::Emitter.new('localhost', 'http', nil, 'get', 0, lambda{ |successes|
        expect(successes).to eq(1)
        callback_executed = true
      })
    emitter.input({'success' => 'good'})
    expect(callback_executed).to eq(true)
  end

  it 'executes a callback on failure' do
    callback_executed = false
    emitter = SnowplowTracker::Emitter.new('nonexistent', 'http', nil, 'get', 0, nil, lambda{ |successes, failures|
        expect(successes).to eq(0)
        expect(failures[0]['failure']).to eq('bad')
        callback_executed = true
      })
    emitter.input({'failure' => 'bad'})
    expect(callback_executed).to eq(true)
  end

end
