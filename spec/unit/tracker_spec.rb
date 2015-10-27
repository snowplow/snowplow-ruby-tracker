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

module SnowplowTracker
  class Tracker

    attr_reader :collector_uri,
                :standard_nv_pairs,
                :config

  end
end

describe SnowplowTracker::Tracker, 'configuration' do

  before(:each) do
    @t = SnowplowTracker::Tracker.new(SnowplowTracker::Emitter.new('d3rkrsqld9gmqf.cloudfront.net'), nil, 'cloudfront', "AF003", false)
  end

  it 'should initialise standard name-value pairs' do
    @t.standard_nv_pairs.should eq({
      'tna' => 'cloudfront',
      'tv' => SnowplowTracker::TRACKER_VERSION,
      'aid' => 'AF003'
    })
  end

  it 'should initialise with the right configuration' do
    @t.config.should eq({'encode_base64' => false, 'tstamp_type' => 'dtm'})
  end

  describe '#set_true_tstamps' do
    it 'can enable and disable true timestamps' do
      @t.set_true_tstamps(true)
      @t.config['tstamp_type'].should eq('ttm')
      @t.set_true_tstamps(false)
      @t.config['tstamp_type'].should eq('dtm')
    end
  end

end
