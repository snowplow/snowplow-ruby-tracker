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

# Author::    Alex Dean, Fred Blundun (mailto:snowplow-user@googlegroups.com)
# Copyright:: Copyright (c) 2013-2014 Snowplow Analytics Ltd
# License::   Apache License Version 2.0
#
# -*- encoding: utf-8 -*-

require_relative 'lib/snowplow-tracker/version'

Gem::Specification.new do |s|
  s.name        = 'snowplow-tracker'
  s.version     = SnowplowTracker::VERSION
  s.homepage    = 'http://github.com/snowplow/snowplow-ruby-tracker'
  s.license     = 'Apache-2.0'
  s.summary     = "Ruby Analytics for Snowplow"
  s.description = "With this tracker you can collect event data from your Ruby applications, Ruby on Rails web applications and Ruby gems."
  s.authors     = ["Alexander Dean", "Fred Blundun"]
  s.email       = 'support@snowplowanalytics.com'
  s.files       = %w(LICENSE-2.0.txt README.md) + Dir.glob('lib/**/*.rb')
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.1'

  s.add_runtime_dependency "contracts", "~> 0.7", "< 0.17"
  s.add_development_dependency "rspec", "~> 2.14.1"
  s.add_development_dependency "webmock", "~> 1.17.4"

end
