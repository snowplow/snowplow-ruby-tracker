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

require 'simplecov'
require 'simplecov-lcov'

# Fix incompatibility of simplecov-lcov with older versions of simplecov that are not expressed in its gemspec.
# https://github.com/fortissimo1997/simplecov-lcov/pull/25
unless SimpleCov.respond_to?(:branch_coverage)
  module SimpleCov
    def self.branch_coverage?
      false
    end
  end
end

SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  c.single_report_path = 'coverage/lcov.info'
end

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ]
)

SimpleCov.start do
  add_filter 'spec/'
end

require 'webmock/rspec'
require 'snowplow-tracker'

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.color = true

  config.before(:each) do
    stub_request(:any, /localhost/)
      .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
      .to_return(status: [200], body: 'stubbed response')
    stub_request(:any, /nonexistent/)
      .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
      .to_return(status: [404], body: 'stubbed response')
  end
end

module SnowplowTracker
  class Emitter
    # Event querystrings will be added here
    @@querystrings = ['']

    # Post request bodies will be added here
    @@post_bodies = [{}]

    old_http_get = instance_method(:http_get)

    define_method(:http_get) do |payload|
      # This additional line records event querystrings
      @@querystrings.push(URI(@collector_uri + '?' + URI.encode_www_form(payload)).query)

      old_http_get.bind(self).call(payload)
    end

    old_http_post = instance_method(:http_post)

    define_method(:http_post) do |payload|
      request = Net::HTTP::Post.new('localhost')
      request.body = payload.to_json

      # This additional line records POST request bodies
      @@post_bodies.push(request.body)

      old_http_post.bind(self).call(payload)
    end

    # New method to get the n-th from last querystring
    def get_last_querystring(n = 1)
      @@querystrings[-n]
    end

    def get_last_body(n = 1)
      @@post_bodies[-n]
    end
  end
end

NULL_LOGGER = Logger.new(IO::NULL).freeze
