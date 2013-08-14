# Copyright (c) 2013 Snowplow Analytics Ltd. All rights reserved.
#
# This program is licensed to you under the Apache License Version 2.0,
# and you may not use this file except in compliance with the Apache License Version 2.0.
# You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the Apache License Version 2.0 is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.

# Author::    Alex Dean (mailto:snowplow-user@googlegroups.com)
# Copyright:: Copyright (c) 2013 Snowplow Analytics Ltd
# License::   Apache License Version 2.0

require 'set'
require 'contracts'
include Contracts

# Custom Contracts.ruby for our Snowplow Tracker
module Snowplow

  # Validate the hash passed to the constructor
  # of a new Tracker
  class NewTrackerHash
    def self.valid?(val)
      val.length == 1 &&
        (val.include("uri") || val.include("cf_subdomin"))
    end
  end

  # Check tracker platform is valid
  class Platform
    @@valid_platforms = Set.new(%w(pc tv mob cnsl iot))

    def self.valid?(val)
      @@valid_platforms.include?(val)
    end
  end

  # Synonym for view dimensions
  # TODO: change to be positive integer
  ViewDimensions = Num, Num
  
end