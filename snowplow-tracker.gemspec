# Copyright (c) 2012-2013 Snowplow Analytics Ltd. All rights reserved.
#
# This program is licensed to you under the Apache License Version 2.0,
# and you may not use this file except in compliance with the Apache License Version 2.0.
# You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the Apache License Version 2.0 is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.
#
# Author:: Alexander Dean (mailto:support@snowplowanalytics.com)
# Copyright:: Copyright (c) 2012-2013 Snowplow Analytics Ltd
# License:: Apache License Version 2.0
#
# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'snowplow-tracker/version'

Gem::Specification.new do |s|
  s.version     = Snowplow::VERSION
  # s.version     = File.read('VERSION').chomp
  s.date        = File.mtime('./lib/snowplow-tracker/version.rb').strftime('%Y-%m-%d')

  s.name        = 'snowplow-tracker'
  s.homepage    = 'http://github.com/snowplow/snowplow-ruby-tracker'
  s.license     = 'Apache License 2.0'
  s.summary     = "Ruby Analytics for Snowplow"
  s.description = "With this tracker you can collect event data from your Ruby applications, Ruby on Rails web applications and Ruby gems."
  s.authors     = ["Alexander Dean"]
  s.email       = 'alex@keplarllp.com'

  # s.platform = Gem::Platform::RUBY
  s.files       = %w(dsl-scratch.rb LICENSE-2.0.txt README.md) + Dir.glob('lib/**/*.rb')
  # s.bindir = %q(bin)
  # s.executables = %w()
  # s.default_executable = gem.executables.first
  # s.require_paths = %w(lib)
  # s.extensions = %w()
  # s.test_files = %w()
  # s.has_rdoc = false

  # s.required_ruby_version = '>= 1.8.1'
  # s.requirements = []
  # s.add_runtime_dependency 'gemname', '>= version'
  # s.add_development_dependency 'gemname' , '>= version'
  # s.post_install_message = nil

end
