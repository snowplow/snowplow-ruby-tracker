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

  # Stores a width x height tuple. Used to express
  # screen resolution, app viewport etc
  class ViewDimensions

    attr_reader :width,
                :height
    # We'll add the setters manually with contracts

    # Constructor for a pair of view dimensions
    #
    # Parameters:
    # +width+:: width of user's screen in pixels
    # +height+:: height of user's screen in pixels
    Contract PosInt, PosInt => ViewDimensions
    def initialize(width, height)
      @width = width
      @height = height
    end

    # String representation of these
    # view dimensions, in the format of the
    # Snowplow Tracker Protocol
    #
    # Returns "heightxwidth"
    Contract => String
    def to_s
      "#{@width}x#{@height}"  
    end

    # Sets the view width
    #
    # Parameters:
    # +width+:: view width, a positive integer
    Contract PosInt => nil
    def width=(width)
      @width = width
    end

    # Sets the view height
    #
    # Parameters:
    # +height+:: view height, a positive integer
    Contract PosInt => nil
    def height=(height)
      @height = height
    end

  end

  # Stores the Context which encapsulates a Snowplow
  # event.
  class Context

    @@default_platform = "pc"

    attr_accessor :name
    attr_reader :platform,          # Manual writer
                :screen_resolution, # Manual writer
                :viewport,          # Manual writer
    # We'll add the setters manually with contracts

    # Constructor for a new event Context.
    # platform must be set in this constructor
    # because all Snowplow events must have a
    # Context.
    #
    # Parameters:
    # +name+:: a name for this Context. Could
    #          be used to indicate scope or a
    #          point in time
    # +platform+:: the device platform which
    #              grounds this Context 
    Contract String, OptionPlatform => Context
    def initialize(name, platform=@@default_platform)
      @name = name
      @platform = platform
    end

    # Setter
    # TODO
    #
    # TODO

    # Creates a copy of this Context with the
    # time modified as supplied
    #
    # Parameters:
    # +timestamp+:: the time to set this Context to
    Contract Time => Contract
    def at(timestamp)
      self.dup.tap do |ctx| 
      ctx.when = timestamp
      end
    end

    # Setter for platform property i.e. the
    # platform on which this tracker is running
    #
    # Parameters:
    # +platform+:: a valid platform code (enforced
    #              by contracts)
    Contract Internal::Platform => nil
    def platform=(platform)
      @platform = platform
      nil
    end

    # Setter for the user's screen resolution
    #
    # Parameters:
    # +view_dimensions+:: a ViewDimensions object
    Contract ViewDimensions => nil
    def screen_resolution=(view_dimensions)
      @screen_resolution = view_dimensions
      nil
    end

    # Setter for app viewport, i.e. the screen
    # space taken up by this app
    #
    # Parameters:
    # +view_dimensions+:: a ViewDimensions object
    Contract ViewDimensions => nil    
    def viewport=(view_dimensions)
      @viewport = view_dimensions
      nil
    end

    # Setter for color depth
    #
    # Parameters:
    # +color_depth+:: color depth
    Contract PosInt => nil
    def color_depth=(color_depth)
      @color_depth = color_depth
      nil
    end

    # Setter for application ID
    #
    # Parameters:
    # +app_id+:: application ID
    Contract String => nil
    def app_id=(app_id)
      @app_id = app_id
    end

    # Contract synonyms
    OptionPlatform = Or[Platform, nil]

    # Check for valid tracker platform
    class Platform
      @@valid_platforms = Set.new(%w(pc tv mob cnsl iot))

      def self.valid?(val)
        @@valid_platforms.include?(val)
      end
    end

end