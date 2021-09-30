# Copyright (c) 2013-2016 Snowplow Analytics Ltd. All rights reserved.
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
# Copyright:: Copyright (c) 2013-2016 Snowplow Analytics Ltd
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
  let(:default_opts) { { logger: NULL_LOGGER } }

  it 'should initialise correctly using default settings' do
    e = SnowplowTracker::Emitter.new(endpoint: 'collector.example.com', options: default_opts)
    expect(e.collector_uri).to eq('http://collector.example.com/i')
    expect(e.buffer_size).to eq(1)
  end

  it 'should initialise correctly using custom settings' do
    on_success = ->(x) { x }
    on_failure = ->(_x, y) { y }
    e = SnowplowTracker::Emitter.new(endpoint: 'collector.example.com', options: default_opts.merge(
      protocol: 'https',
      port: 80,
      path: '/specific-path',
      method: 'post',
      buffer_size: 7,
      on_success: on_success,
      on_failure: on_failure
    ))
    expect(e.collector_uri).to eq('https://collector.example.com:80/specific-path')
    expect(e.buffer_size).to eq(7)
    expect(e.on_success).to eq(on_success)
    expect(e.on_failure).to eq(on_failure)
  end
end

describe SnowplowTracker::Emitter, 'Sending requests' do
  let(:default_opts) { { logger: NULL_LOGGER } }

  it 'sends a payload' do
    emitter = SnowplowTracker::Emitter.new(endpoint: 'localhost', options: default_opts)
    emitter.input('key' => 'value')
    param_hash = CGI.parse(emitter.get_last_querystring)
    expect(param_hash['key'][0]).to eq('value')
    expect(param_hash['stm'][0].to_i.round(-4)).to eq((Time.now.to_f * 1000).to_i.round(-4))
  end

  it 'executes a callback on success' do
    callback_executed = false
    emitter = SnowplowTracker::Emitter.new(endpoint: 'localhost', options: default_opts.merge(
      on_success: ->(successes) {
        expect(successes).to eq(1)
        callback_executed = true
      }
    ))
    emitter.input('success' => 'good')
    expect(callback_executed).to eq(true)
  end

  it 'executes a callback on failure' do
    callback_executed = false
    emitter = SnowplowTracker::Emitter.new(endpoint: 'nonexistent', options: default_opts.merge(
      on_failure: ->(successes, failures) {
        expect(successes).to eq(0)
        expect(failures[0]['failure']).to eq('bad')
        callback_executed = true
      }
    ))
    emitter.input('failure' => 'bad')
    expect(callback_executed).to eq(true)
  end

  it 'correctly batches multiple events' do
    emitter = SnowplowTracker::Emitter.new(endpoint: 'localhost', options: default_opts.merge(
      method: 'post', buffer_size: 3
    ))
    emitter.input('key1' => 'value1')
    emitter.input('key2' => 'value2')
    emitter.input('key3' => 'value3')

    sent = JSON.parse(emitter.get_last_body(1))

    expect(sent['schema']).to eq('iglu:com.snowplowanalytics.snowplow/payload_data/jsonschema/1-0-4')

    expect(sent['data'][0]['key1']).to eq('value1')
    expect(sent['data'][0]['stm'].to_i.round(-4)).to eq((Time.now.to_f * 1000).to_i.round(-4))

    expect(sent['data'][1]['key2']).to eq('value2')
    expect(sent['data'][1]['stm'].to_i.round(-4)).to eq((Time.now.to_f * 1000).to_i.round(-4))

    expect(sent['data'][2]['key3']).to eq('value3')
    expect(sent['data'][2]['stm'].to_i.round(-4)).to eq((Time.now.to_f * 1000).to_i.round(-4))
  end
end

describe SnowplowTracker::AsyncEmitter, 'Synchronous flush' do
  let(:default_opts) { { logger: NULL_LOGGER } }

  it 'sends all events synchronously' do
    emitter = SnowplowTracker::AsyncEmitter.new(endpoint: 'localhost', options: default_opts.merge(buffer_size: 6))
    emitter.input('key' => 'value')
    emitter.flush(false)
    param_hash = CGI.parse(emitter.get_last_querystring)
    expected_fields = {
      'key' => 'value'
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }
  end
end
