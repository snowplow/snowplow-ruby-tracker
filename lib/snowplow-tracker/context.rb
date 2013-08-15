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

require 'contracts'
include Contracts

module Snowplow

  class Context

    @@default_platform = "pc"

    attr_reader :platform,

                :screen_resolution,
                :viewport,

    # Setter for platform property i.e. the
    # platform on which this tracker is running
    #
    # Parameters:
    # +platform+:: a valid platform code (enforced
    #              by contracts)
    Contract Platform => nil
    def platform=(platform)
      @platform = platform
      nil
    end

    # Setter for the user's screen resolution
    #

    Contract ViewDimensions => nil
    def screen_resolution=(width, height)
      @screen_resolution = screen_resolution
      nil
    end

    # Setter for app viewport, i.e. the screen
    # space taken up by this app
    #
    # Parameters:
    # +width+:: width of user's screen in pixels
    # +height+:: height of user's screen in pixels
    Contract ViewDimensions => nil    
    def viewport=(width, height)
      @viewport = viewport
      nil
    end

  end

  module Internal

    # Check for valid tracker platform
    class Platform
      @@valid_platforms = Set.new(%w(pc tv mob cnsl iot))

      def self.valid?(val)
        @@valid_platforms.include?(val)
      end
    end
    
  end

end