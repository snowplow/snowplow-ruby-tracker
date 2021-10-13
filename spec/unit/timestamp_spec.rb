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

describe SnowplowTracker::Timestamp do
  it 'has a type' do
    expect(SnowplowTracker::Timestamp.new('dtm', 1633599642991).type).to eq('dtm')
  end

  it 'has a value' do
    expect(SnowplowTracker::Timestamp.new('dtm', 1633599642991).value).to eq(1633599642991)
  end
end

describe SnowplowTracker::TrueTimestamp do
  it 'has type ttm' do
    expect(SnowplowTracker::TrueTimestamp.new(1633599642991).type).to eq('ttm')
  end

  it 'has a value' do
    expect(SnowplowTracker::TrueTimestamp.new(1633599642991).value).to eq(1633599642991)
  end
end

describe SnowplowTracker::DeviceTimestamp do
  it 'has type dtm' do
    expect(SnowplowTracker::DeviceTimestamp.new(1234567890123).type).to eq('dtm')
  end

  it 'has a value' do
    expect(SnowplowTracker::DeviceTimestamp.new(1234567890123).value).to eq(1234567890123)
  end
end
