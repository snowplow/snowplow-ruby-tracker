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
require 'json'

module SnowplowTracker
  class Emitter

    attr_reader :collector_uri,
                :buffer_size,
                :on_success,
                :on_failure

  end
end

describe SnowplowTracker::Emitter, 'configuration' do

  it 'should initialise correctly using default settings' do
    e = SnowplowTracker::Emitter.new('d3rkrsqld9gmqf.cloudfront.net')
    expect(e.collector_uri).to eq('http://d3rkrsqld9gmqf.cloudfront.net/i')
    expect(e.buffer_size).to eq(1)
  end

  it 'should initialise correctly using custom settings' do
    on_success = lambda{ |x| puts x}
    on_failure = lambda{ |x,y| puts y}
    e = SnowplowTracker::Emitter.new('d3rkrsqld9gmqf.cloudfront.net', {
      :protocol => 'https',
      :port => 80,
      :method => 'post',
      :buffer_size => 7,
      :on_success => on_success,
      :on_failure => on_failure
    })
    expect(e.collector_uri).to eq('https://d3rkrsqld9gmqf.cloudfront.net:80/com.snowplowanalytics.snowplow/tp2')
    expect(e.buffer_size).to eq(7)
    expect(e.on_success).to eq(on_success)
    expect(e.on_failure).to eq(on_failure)
  end

end

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
    emitter = SnowplowTracker::Emitter.new('localhost', {
      :on_success => lambda { |successes|
        expect(successes).to eq(1)
        callback_executed = true
      }
    })
    emitter.input({'success' => 'good'})
    expect(callback_executed).to eq(true)
  end

  it 'executes a callback on failure' do
    callback_executed = false
    emitter = SnowplowTracker::Emitter.new('nonexistent', {
      :on_failure => lambda { |successes, failures|
        expect(successes).to eq(0)
        expect(failures[0]['failure']).to eq('bad')
        callback_executed = true
      }
    })
    emitter.input({'failure' => 'bad'})
    expect(callback_executed).to eq(true)
  end

  it 'correctly batches multiple events' do
    emitter = SnowplowTracker::Emitter.new('localhost', {:method => 'post', :buffer_size => 3})
    emitter.input({"key1" => "value1"})
    emitter.input({"key2" => "value2"})
    emitter.input({"key3" => "value3"})

    expect(JSON.parse(emitter.get_last_body(1))).to eq({
      "schema" => "iglu:com.snowplowanalytics.snowplow/payload_data/jsonschema/1-0-2",
      "data" => [
        {"key1" => "value1"},
        {"key2"=>"value2"},
        {"key3"=>"value3"}
      ]
    })


  end

end

describe SnowplowTracker::AsyncEmitter, 'Synchronous flush' do

  it 'sends all events synchronously' do
    emitter = SnowplowTracker::AsyncEmitter.new('localhost',{:buffer_size => 6})
    emitter.input({'key' => 'value'})
    emitter.flush(false)
    param_hash = CGI.parse(emitter.get_last_querystring)
    expected_fields = {
      'key' => 'value'}
    for pair in expected_fields
      expect(param_hash[pair[0]][0]).to eq(pair[1])
    end
  end

end
