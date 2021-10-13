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


# The Snowplow Ruby Tracker allows you to track Snowplow events in your Ruby
# applications and gems and Ruby on Rails web applications.
#
# It is compatible with Ruby versions 2.1 to 3.0+.
#
# See the [demo Rails
# app](https://github.com/snowplow-incubator/snowplow-ruby-tracker-examples) to
# see an example of how to incorporate the Snowplow Ruby tracker in Ruby on
# Rails app.
#
# # Type checking
#
# This gem uses the [Contracts](https://github.com/egonSchiele/contracts.ruby)
# gem for typechecking. This cannot be disabled. The {Tracker} `track_x_event`
# methods expect arguments of a certain type. If a check fails, a runtime error
# is thrown.
#
# @see https://github.com/snowplow/snowplow-ruby-tracker
#   Ruby tracker on Github
# @see https://github.com/snowplow-incubator/snowplow-ruby-tracker-examples
#   Snowplow Ruby tracker examples in a demo Rails app
# @see https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/ruby-tracker/
#   Snowplow documentation
# @see https://snowplowanalytics.com/ Snowplow homepage
# @api public
module SnowplowTracker
  # The version of Ruby Snowplow tracker you are using
  VERSION = '0.7.0-alpha.2'

  # All events from this tracker will have this string
  TRACKER_VERSION = "rb-#{VERSION}"
end
