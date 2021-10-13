# Copyright (c) 2013-2021 Snowplow Analytics Ltd. All rights reserved.
#
# This program is licensed to you under the Apache License Version 2.0,
# and you may not use this file except in compliance with the Apache License Version 2.0.
# You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the Apache License Version 2.0 is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.

# Author:: Snowplow Analytics Ltd
# Copyright:: Copyright (c) 2013-2021 Snowplow Analytics Ltd
# License:: Apache License Version 2.0

require 'spec_helper'

module SnowplowTracker
  class Tracker
    attr_reader :collector_uri,
                :settings,
                :encode_base64
  end
end

describe SnowplowTracker::Tracker, 'configuration' do
  let(:emitter) do
    SnowplowTracker::Emitter.new(endpoint: 'collector.example.com',
                                 options: { logger: NULL_LOGGER })
  end

  before(:each) do
    @t = SnowplowTracker::Tracker.new(emitters: emitter, namespace: 'example', app_id: 'AF003', encode_base64: false)
  end

  it 'should initialise standard name-value pairs' do
    expect(@t.settings).to eq(
      'tna' => 'example',
      'tv' => SnowplowTracker::TRACKER_VERSION,
      'aid' => 'AF003'
    )
  end

  it 'should initialise with the right configuration' do
    expect(@t.encode_base64).to eq false
  end
end
