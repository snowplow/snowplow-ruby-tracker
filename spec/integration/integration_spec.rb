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

describe SnowplowTracker::Tracker, 'Querystring construction' do
  let(:emitter_opts) { { logger: NULL_LOGGER } }
  let(:e) { SnowplowTracker::Emitter.new('localhost', emitter_opts) }
  let(:t) { SnowplowTracker::Tracker.new(e) }

  SelfDescribingJson = SnowplowTracker::SelfDescribingJson

  it 'tracks a page view' do
    t.track_page_view('http://example.com', 'Two words', 'http://www.referrer.com', nil, 123)
    param_hash = CGI.parse(e.get_last_querystring)
    expected_fields = {
      'e' => 'pv',
      'page' => 'Two words',
      'refr' => 'http://www.referrer.com',
      'dtm' => '123'
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }
  end

  it 'tracks an ecommerce transaction' do
    t.track_ecommerce_transaction(
      {
        'order_id' => '12345',
        'total_value' => 35,
        'affiliation' => 'my_company',
        'tax_value' => 0,
        'shipping' => 0,
        'city' => 'Phoenix',
        'state' => 'Arizona',
        'country' => 'USA',
        'currency' => 'GBP'
      },
      [
        {
          'sku' => 'pbz0026',
          'price' => 20,
          'quantity' => 1
        },
        {
          'sku' => 'pbz0038',
          'price' => 15,
          'quantity' => 1,
          'name' => 'crystals',
          'category' => 'magic'
        }
      ]
    )

    param_hash = CGI.parse(e.get_last_querystring(3))
    expected_fields = {
      'e' => 'tr',
      'tr_id' => '12345',
      'tr_tt' => '35',
      'tr_af' => 'my_company',
      'tr_tx' => '0',
      'tr_sh' => '0',
      'tr_ci' => 'Phoenix',
      'tr_st' => 'Arizona',
      'tr_co' => 'USA',
      'tr_cu' => 'GBP'
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }

    param_hash = CGI.parse(e.get_last_querystring(2))
    expected_fields = {
      'e' => 'ti',
      'ti_id' => '12345',
      'ti_sk' => 'pbz0026',
      'ti_cu' => 'GBP',
      'ti_pr' => '20'
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }

    param_hash = CGI.parse(e.get_last_querystring(1))
    expected_fields = {
      'e' => 'ti',
      'ti_id' => '12345',
      'ti_sk' => 'pbz0038',
      'ti_nm' => 'crystals',
      'ti_ca' => 'magic',
      'ti_cu' => 'GBP',
      'ti_pr' => '15'
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }

    %w[dtm tid].each do |field|
      expect(CGI.parse(e.get_last_querystring(1))[field]).to eq(CGI.parse(e.get_last_querystring(3))[field])
    end
  end

  it 'tracks a structured event' do
    t.track_struct_event('Ecomm', 'add-to-basket', 'dog-skateboarding-video', 'hd', 13.99)

    param_hash = CGI.parse(e.get_last_querystring(1))
    expected_fields = {
      'e' => 'se',
      'se_ca' => 'Ecomm',
      'se_ac' => 'add-to-basket',
      'se_pr' => 'hd',
      'se_va' => '13.99'
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }
  end

  it 'tracks a (non base64) self describing event in the same way as an unstructured event' do
    t = SnowplowTracker::Tracker.new(e, nil, nil, nil, false)
    t.track_self_describing_event(SelfDescribingJson.new(
                                    'iglu:com.acme/viewed_product/jsonschema/1-0-0',
                                    'product_id' => 'ASO01043',
                                    'price' => 49.95
                                  ))

    param_hash = CGI.parse(e.get_last_querystring(1))
    expected_fields = {
      'e' => 'ue',
      'ue_pr' => '{"schema":"iglu:com.snowplowanalytics.snowplow/unstruct_event/jsonschema/1-0-0",'\
                  '"data":{"schema":"iglu:com.acme/viewed_product/jsonschema/1-0-0",'\
                  '"data":{"product_id":"ASO01043","price":49.95}}}'
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }
  end

  it 'tracks a base64 encoded self describing event in the same way as an unstructured_event' do
    t.track_self_describing_event(SelfDescribingJson.new(
                                    'iglu:com.acme/viewed_product/jsonschema/1-0-0',
                                    'product_id' => 'ASO01043',
                                    'price' => 49.95
                                  ))

    param_hash = CGI.parse(e.get_last_querystring(1))
    expected_fields = {
      'e' => 'ue',
      'ue_px' =>  'eyJzY2hlbWEiOiJpZ2x1OmNvbS5zbm93cGxvd2FuYWx5dGljcy5zbm93cGxvdy91bnN0cnVjd'\
                  'F9ldmVudC9qc29uc2NoZW1hLzEtMC0wIiwiZGF0YSI6eyJzY2hlbWEiOiJpZ2x1OmNvbS5hY2'\
                  '1lL3ZpZXdlZF9wcm9kdWN0L2pzb25zY2hlbWEvMS0wLTAiLCJkYXRhIjp7InByb2R1Y3RfaWQ'\
                  'iOiJBU08wMTA0MyIsInByaWNlIjo0OS45NX19fQ=='
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }
  end

  it 'tracks an unstructured event (no base64)' do
    t = SnowplowTracker::Tracker.new(e, nil, nil, nil, false)
    t.track_unstruct_event(SelfDescribingJson.new(
                             'iglu:com.acme/viewed_product/jsonschema/1-0-0',
                             'product_id' => 'ASO01043',
                             'price' => 49.95
                           ))

    param_hash = CGI.parse(e.get_last_querystring(1))
    expected_fields = {
      'e' => 'ue',
      'ue_pr' => '{"schema":"iglu:com.snowplowanalytics.snowplow/unstruct_event/jsonschema/1-0-0",'\
                  '"data":{"schema":"iglu:com.acme/viewed_product/jsonschema/1-0-0",'\
                  '"data":{"product_id":"ASO01043","price":49.95}}}'
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }
  end

  it 'tracks an unstructured event (base64)' do
    t.track_unstruct_event(SelfDescribingJson.new(
                             'iglu:com.acme/viewed_product/jsonschema/1-0-0',
                             'product_id' => 'ASO01043',
                             'price' => 49.95
                           ))

    param_hash = CGI.parse(e.get_last_querystring(1))
    expected_fields = {
      'e' => 'ue',
      'ue_px' =>  'eyJzY2hlbWEiOiJpZ2x1OmNvbS5zbm93cGxvd2FuYWx5dGljcy5zbm93cGxvdy91bnN0cnVjdF'\
                  '9ldmVudC9qc29uc2NoZW1hLzEtMC0wIiwiZGF0YSI6eyJzY2hlbWEiOiJpZ2x1OmNvbS5hY21l'\
                  'L3ZpZXdlZF9wcm9kdWN0L2pzb25zY2hlbWEvMS0wLTAiLCJkYXRhIjp7InByb2R1Y3RfaWQiOi'\
                  'JBU08wMTA0MyIsInByaWNlIjo0OS45NX19fQ=='
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }
  end

  it 'tracks a screen view unstructured event' do
    t = SnowplowTracker::Tracker.new(e, nil, nil, nil, false)
    t.track_screen_view('Game HUD 2', 'e89a34b2f')

    param_hash = CGI.parse(e.get_last_querystring(1))
    expected_fields = {
      'e' => 'ue',
      'ue_pr' => '{"schema":"iglu:com.snowplowanalytics.snowplow/unstruct_event/jsonschema/1-0-0",'\
                  '"data":{"schema":"iglu:com.snowplowanalytics.snowplow/screen_view/jsonschema/1-0-0",'\
                  '"data":{"name":"Game HUD 2","id":"e89a34b2f"}}}'
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }
  end

  it 'adds standard name-value pairs to the payload' do
    t = SnowplowTracker::Tracker.new(e, nil, 'cf', 'angry-birds-android')
    t.set_platform('mob')
    t.set_user_id('user12345')
    t.set_screen_resolution(400, 200)
    t.set_viewport(100, 80)
    t.set_color_depth(24)
    t.set_timezone('Europe London')
    t.set_lang('en')
    t.set_fingerprint(987654321)
    t.track_page_view('http://www.example.com', 'title page')

    param_hash = CGI.parse(e.get_last_querystring(1))
    expected_fields = {
      'tna' => 'cf',
      'res' => '400x200',
      'vp' => '100x80',
      'lang' => 'en',
      'aid' => 'angry-birds-android',
      'cd' => '24',
      'tz' => 'Europe London',
      'p' => 'mob',
      'fp' => '987654321',
      'tv' => SnowplowTracker::TRACKER_VERSION
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }
  end

  it 'can have more than one Subject' do
    t = SnowplowTracker::Tracker.new(e, SnowplowTracker::Subject.new, 'cf', 'angry-birds-android')
    t.set_platform('mob')
    t.set_user_id('user12345')
    t.set_screen_resolution(400, 200)
    t.set_viewport(100, 80)
    t.set_color_depth(24)
    t.set_timezone('Europe London')
    t.set_lang('en')
    t.set_domain_user_id('aeb1691c5a0ee5a6')
    t.set_ip_address('255.255.255.255')
    t.set_useragent('Mozilla/5.0')
    t.set_network_user_id('ecdff4d0-9175-40ac-a8bb-325c49733607')
    t.set_fingerprint(987654321)
    t.track_page_view('http://www.example.com', 'title page')

    param_hash = CGI.parse(e.get_last_querystring(1))
    expected_fields = {
      'tna' => 'cf',
      'res' => '400x200',
      'vp' => '100x80',
      'lang' => 'en',
      'aid' => 'angry-birds-android',
      'cd' => '24',
      'tz' => 'Europe London',
      'p' => 'mob',
      'duid' => 'aeb1691c5a0ee5a6',
      'ua' => 'Mozilla/5.0',
      'ip' => '255.255.255.255',
      'tnuid' => 'ecdff4d0-9175-40ac-a8bb-325c49733607',
      'fp' => '987654321',
      'tv' => SnowplowTracker::TRACKER_VERSION
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }

    s = SnowplowTracker::Subject.new.set_viewport(100, 100).set_lang('fr')
    t.set_subject(s)
    t.set_user_id('another_user')
    t.track_page_view('http://www.example.com', 'title page')

    param_hash2 = CGI.parse(e.get_last_querystring(1))
    expected_fields2 = {
      'tna' => 'cf',
      'res' => nil,
      'vp' => '100x100',
      'lang' => 'fr',
      'aid' => 'angry-birds-android',
      'cd' => nil,
      'tz' => nil,
      'p' => 'srv',
      'tv' => SnowplowTracker::TRACKER_VERSION
    }
    expected_fields2.each { |pair| expect(param_hash2[pair[0]][0]).to eq(pair[1]) }
  end

  it 'adds a custom context to the payload' do
    t = SnowplowTracker::Tracker.new(e, nil, nil, nil, false)
    t.track_page_view('http://www.example.com', nil, nil, [
                        SelfDescribingJson.new(
                          'iglu:com.acme/page/jsonschema/1-0-0',
                          'page_type' => 'test'
                        ),
                        SelfDescribingJson.new(
                          'iglu:com.acme/user/jsonschema/1-0-0',
                          'user_type' => 'tester'
                        )
                      ])

    param_hash = CGI.parse(e.get_last_querystring(1))
    expected_fields = {
      'co' => '{"schema":"iglu:com.snowplowanalytics.snowplow/contexts/jsonschema/1-0-1",'\
              '"data":[{"schema":"iglu:com.acme/page/jsonschema/1-0-0","data":{"page_type":"test"}},'\
              '{"schema":"iglu:com.acme/user/jsonschema/1-0-0","data":{"user_type":"tester"}}]}'
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }
  end

  it 'batches and sends multiple events using GET' do
    e = SnowplowTracker::Emitter.new('localhost', emitter_opts.merge(buffer_size: 3))
    t = SnowplowTracker::Tracker.new(e)
    t.track_page_view('http://www.example.com', 'first')
    t.track_page_view('http://www.example.com', 'second')
    t.track_page_view('http://www.example.com', 'third')

    param_hash1 = CGI.parse(e.get_last_querystring(1))
    expect(param_hash1['page'][0]).to eq('third')

    param_hash2 = CGI.parse(e.get_last_querystring(2))
    expect(param_hash2['page'][0]).to eq('second')

    param_hash3 = CGI.parse(e.get_last_querystring(3))
    expect(param_hash3['page'][0]).to eq('first')
  end

  it 'batches and sends multiple events using POST' do
    e = SnowplowTracker::Emitter.new('localhost', emitter_opts.merge(method: 'post', buffer_size: 3))
    t = SnowplowTracker::Tracker.new(e)
    t.track_page_view('http://www.example.com', 'fourth')
    t.track_page_view('http://www.example.com', 'fifth')
    t.track_page_view('http://www.example.com', 'sixth')

    payload_data = JSON.parse(e.get_last_body)['data']
    expect(payload_data[0]['page']).to eq('fourth')
    expect(payload_data[1]['page']).to eq('fifth')
    expect(payload_data[2]['page']).to eq('sixth')
  end

  it 'supports true timestamps on page view tracking' do
    t.track_page_view(
      'http://example.com',
      'Two words',
      'http://www.referrer.com',
      nil,
      SnowplowTracker::TrueTimestamp.new(123)
    )

    param_hash = CGI.parse(e.get_last_querystring)
    expected_fields = {
      'e' => 'pv',
      'page' => 'Two words',
      'refr' => 'http://www.referrer.com',
      'ttm' => '123'
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }
  end

  it 'supports true timestamps on ecommerce transactions' do
    t.track_ecommerce_transaction(
      {
        'order_id' => '12345',
        'total_value' => 35,
        'affiliation' => 'my_company',
        'tax_value' => 0,
        'shipping' => 0,
        'city' => 'Phoenix',
        'state' => 'Arizona',
        'country' => 'USA',
        'currency' => 'GBP'
      },
      [
        {
          'sku' => 'pbz0026',
          'price' => 20,
          'quantity' => 1
        },
        {
          'sku' => 'pbz0038',
          'price' => 15,
          'quantity' => 1,
          'name' => 'crystals',
          'category' => 'magic'
        }
      ],
      nil,
      SnowplowTracker::TrueTimestamp.new(123456)
    )

    %w[ttm tid].each do |field|
      expect(CGI.parse(e.get_last_querystring(1))[field]).to eq(CGI.parse(e.get_last_querystring(3))[field])
    end
  end

  it 'tracks a structured event with a true timestamp' do
    t.track_struct_event(
      'Ecomm',
      'add-to-basket',
      'dog-skateboarding-video',
      'hd',
      13.99,
      nil,
      SnowplowTracker::TrueTimestamp.new(123)
    )

    param_hash = CGI.parse(e.get_last_querystring(1))
    expected_fields = {
      'e' => 'se',
      'se_ca' => 'Ecomm',
      'se_ac' => 'add-to-basket',
      'se_pr' => 'hd',
      'se_va' => '13.99',
      'ttm' => '123'
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }
  end

  it 'tracks a screen view unstructured event with a true timestamp' do
    t = SnowplowTracker::Tracker.new(e, nil, nil, nil, false)
    t.track_screen_view('Game HUD 2', 'e89a34b2f', nil, SnowplowTracker::TrueTimestamp.new(123))

    param_hash = CGI.parse(e.get_last_querystring(1))
    expected_fields = {
      'e' => 'ue',
      'ue_pr' => '{"schema":"iglu:com.snowplowanalytics.snowplow/unstruct_event/jsonschema/1-0-0",'\
                  '"data":{"schema":"iglu:com.snowplowanalytics.snowplow/screen_view/jsonschema/1-0-0",'\
                  '"data":{"name":"Game HUD 2","id":"e89a34b2f"}}}',
      'ttm' => '123'
    }
    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }
  end

  it 'tracks a self describing event with a true timestamp' do
    t = SnowplowTracker::Tracker.new(e, nil, nil, nil, false)
    t.track_self_describing_event(SelfDescribingJson.new(
                                    'iglu:com.acme/viewed_product/jsonschema/1-0-0',
                                    'product_id' => 'ASO01043',
                                    'price' => 49.95
                                  ), nil, SnowplowTracker::TrueTimestamp.new(1234))

    param_hash = CGI.parse(e.get_last_querystring(1))
    expected_fields = {
      'e' => 'ue',
      'ue_pr' => '{"schema":"iglu:com.snowplowanalytics.snowplow/unstruct_event/jsonschema/1-0-0",'\
                  '"data":{"schema":"iglu:com.acme/viewed_product/jsonschema/1-0-0",'\
                  '"data":{"product_id":"ASO01043","price":49.95}}}',
      'ttm' => '1234'
    }

    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }
  end

  it 'tracks a self describing event with a device timestamp' do
    t = SnowplowTracker::Tracker.new(e, nil, nil, nil, false)
    t.track_self_describing_event(SelfDescribingJson.new(
                                    'iglu:com.acme/viewed_product/jsonschema/1-0-0',
                                    'product_id' => 'ASO01043',
                                    'price' => 49.95
                                  ), nil, 555)

    param_hash = CGI.parse(e.get_last_querystring(1))
    expected_fields = {
      'e' => 'ue',
      'ue_pr' => '{"schema":"iglu:com.snowplowanalytics.snowplow/unstruct_event/jsonschema/1-0-0",'\
                  '"data":{"schema":"iglu:com.acme/viewed_product/jsonschema/1-0-0",'\
                  '"data":{"product_id":"ASO01043","price":49.95}}}',
      'dtm' => '555'
    }

    expected_fields.each { |pair| expect(param_hash[pair[0]][0]).to eq(pair[1]) }
  end
end
