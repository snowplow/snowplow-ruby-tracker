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

describe SnowplowTracker::Payload, 'data' do
  before(:each) do
    @payload = SnowplowTracker::Payload.new
  end

  it 'initializes with an empty data hash' do
    expect(@payload.data).to eq({})
  end

  it 'adds single key-value pairs to the data' do
    @payload.add('key1', 'value1')
    @payload.add('key2', 'value2')
    expect(@payload.data).to eq('key1' => 'value1', 'key2' => 'value2')
  end

  it 'adds a dictionary of key-value pairs to the data' do
    @payload.add_hash(
      'p' => 'mob',
      'tna' => 'cf',
      'aid' => 'cd767ae'
    )
    expect(@payload.data).to eq(
      'p' => 'mob',
      'tna' => 'cf',
      'aid' => 'cd767ae'
    )
  end

  it 'turns a JSON into a string and adds it to the data' do
    @payload.add_json({ 'a' => { 'b' => [23, 54] } }, false, 'cx', 'co')
    expect(@payload.data).to eq(
      'co' => '{"a":{"b":[23,54]}}'
    )
  end

  it 'base64-encodes a JSON string' do
    @payload.add_json({ 'a' => { 'b' => [23, 54] } }, true, 'cx', 'co')
    expect(@payload.data).to eq(
      'cx' => 'eyJhIjp7ImIiOlsyMyw1NF19fQ=='
    )
  end
end
