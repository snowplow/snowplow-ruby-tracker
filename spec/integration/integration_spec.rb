# Copyright (c) 2013-2014 SnowPlow Analytics Ltd. All rights reserved.
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
# Copyright:: Copyright (c) 2013-2014 SnowPlow Analytics Ltd
# License:: Apache License Version 2.0

require 'spec_helper'
require 'cgi'

module Snowplow
  class Tracker

    # Event querystrings will be added here
    @@querystrings = ['']

    def http_get(payload)

      # This additional line records event querystrings
      @@querystrings.push(URI(@collector_uri + '?' + URI.encode_www_form(payload.context)).query)

      destination = URI(@collector_uri + '?' + URI.encode_www_form(payload.context))
      r = Net::HTTP.get_response(destination)
      if @@http_errors.include? r.code
        return false, "Host [#{r.host}] not found (possible connectivity error)"
      elsif r.code.to_i < 0 or 400 <= r.code.to_i
        return false, r.code.to_i
      else
        return true, r.code.to_i
      end

    end

    # New method to get the n-th from last querystring
    def get_last_querystring(n=1)
      return @@querystrings[-n]
    end

  end
end


describe Snowplow::Tracker, 'Querystring construction' do

  it 'tracks a page view' do
    t = Snowplow::Tracker.new('localhost')
    t.track_page_view('http://example.com', 'Two words', 'http://www.referrer.com')
    param_hash = CGI.parse(t.get_last_querystring)
    expected_fields = {'e' => 'pv', 'page' => 'Two words', 'refr' => 'http://www.referrer.com'}
    for pair in expected_fields
      expect(param_hash[pair[0]][0]).to eq(pair[1])
    end
  end
    
  it 'tracks an ecommerce transaction' do
    t = Snowplow::Tracker.new('localhost')
    t.track_ecommerce_transaction({
      'order_id' => '12345',
      'total_value' => 35,
      'city' => 'London',
      'currency' => 'GBP'
      },
      [ {
      'sku' => 'pbz0026',
      'price' => 20,
      'quantity' => 1
      },
      {
      'sku' => 'pbz0038',
      'price' => 15,
      'quantity' => 1
  }])

    param_hash = CGI.parse(t.get_last_querystring(3))
    expected_fields = {'e' => 'tr', 'tr_id' => '12345', 'tr_tt' => '35', 'tr_ci' => 'London', 'tr_cu' => 'GBP'}
    for pair in expected_fields
      expect(param_hash[pair[0]][0]).to eq(pair[1])
    end    

    param_hash = CGI.parse(t.get_last_querystring(2))
    expected_fields = {'e' => 'ti', 'ti_id' => '12345', 'ti_sk' => 'pbz0026', 'ti_cu' => 'GBP', 'ti_pr' => '20'}
    for pair in expected_fields
      expect(param_hash[pair[0]][0]).to eq(pair[1])
    end    

    param_hash = CGI.parse(t.get_last_querystring(1))
    expected_fields = {'e' => 'ti', 'ti_id' => '12345', 'ti_sk' => 'pbz0038', 'ti_cu' => 'GBP', 'ti_pr' => '15'}
    for pair in expected_fields
      expect(param_hash[pair[0]][0]).to eq(pair[1])
    end

    ['dtm', 'tid'].each do |field|
      expect(CGI.parse(t.get_last_querystring(1))[field]).to eq(CGI.parse(t.get_last_querystring(3))[field])
    end

  end

  it 'tracks a structured event' do
    t = Snowplow::Tracker.new('localhost')
    t.track_struct_event('Ecomm', 'add-to-basket', 'dog-skateboarding-video', 'hd', 13.99)

    param_hash = CGI.parse(t.get_last_querystring(1))
    expected_fields = {'e' => 'se', 'se_ca' => 'Ecomm', 'se_ac' => 'add-to-basket', 'se_pr' => 'hd', 'se_va' => '13.99'}
    for pair in expected_fields
      expect(param_hash[pair[0]][0]).to eq(pair[1])
    end    

  end

  it 'tracks an unstructured event (no base64)' do
    t = Snowplow::Tracker.new('localhost', nil, nil, false)
    t.track_unstruct_event('viewed_product', {'product_id' => 'ASO01043', 'price' => 49.95}, 'com.example')

    param_hash = CGI.parse(t.get_last_querystring(1))
    expected_fields = {'e' => 'ue', 'ue_pr' => "{\"product_id\":\"ASO01043\",\"price\":49.95}", 'evn' => 'com.example'}
    for pair in expected_fields
      expect(param_hash[pair[0]][0]).to eq(pair[1])
    end

  end

  it 'tracks an unstructured event (base64)' do
    t = Snowplow::Tracker.new('localhost')
    t.track_unstruct_event('viewed_product', {'product_id' => 'ASO01043', 'price' => 49.95}, 'com.example')

    param_hash = CGI.parse(t.get_last_querystring(1))
    expected_fields = {'e' => 'ue', 'ue_px' => 'eyJwcm9kdWN0X2lkIjoiQVNPMDEwNDMiLCJwcmljZSI6NDkuOTV9', 'evn' => 'com.example'}
    for pair in expected_fields
      expect(param_hash[pair[0]][0]).to eq(pair[1])
    end

  end

  it 'tracks a screen view unstructured event' do
    t = Snowplow::Tracker.new('localhost', nil, nil, false)
    t.track_screen_view('Game HUD 2', 'e89a34b2f')

    param_hash = CGI.parse(t.get_last_querystring(1))
    expected_fields = {'e' => 'ue', 'ue_pr' => "{\"name\":\"Game HUD 2\",\"id\":\"e89a34b2f\"}", 'evn' => 'com.snowplowanalytics'}
    for pair in expected_fields
      expect(param_hash[pair[0]][0]).to eq(pair[1])
    end

  end

  it 'adds standard name-value pairs to the payload' do
    t = Snowplow::Tracker.new('localhost', 'cf', 'angry-birds-android')
    t.set_platform('mob')
    t.set_user_id('user12345')
    t.set_screen_resolution(400, 200)
    t.set_viewport(100, 80)
    t.set_color_depth(24)
    t.set_timezone('Europe London')
    t.set_lang('en')
    t.track_page_view('http://www.example.com', 'title page')

    param_hash = CGI.parse(t.get_last_querystring(1))
    expected_fields = {
      'tna' => 'cf', 
      'evn' => 'com.snowplowanalytics', 
      'res' => '400x200',
      'vp' => '100x80',
      'lang' => 'en', 
      'aid' => 'angry-birds-android', 
      'cd' => '24', 
      'tz' => 'Europe London', 
      'p' => 'mob', 
      'tv' => Snowplow::TRACKER_VERSION}
    for pair in expected_fields
      expect(param_hash[pair[0]][0]).to eq(pair[1])
    end

  end

  it 'adds a custom context to the payload' do
    t = Snowplow::Tracker.new('localhost', nil, nil, false)
    t.track_page_view('http://www.example.com', nil, nil, {
      'page' => {
        'page_type' => 'test'
        }, 
      'user' => {
        'user_type' => 'tester'
        }
      })

    param_hash = CGI.parse(t.get_last_querystring(1))
    expected_fields = {'co' => "{\"page\":{\"page_type\":\"test\"},\"user\":{\"user_type\":\"tester\"}}"}
    for pair in expected_fields
      expect(param_hash[pair[0]][0]).to eq(pair[1])
    end

  end

end
