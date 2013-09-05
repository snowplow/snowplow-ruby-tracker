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

  # Check for valid tracker platform
  class Platform
    @@valid_platforms = Set.new(%w(web pc tv mob cnsl iot))

    def self.valid?(val)
      @@valid_platforms.include?(val)
    end
  end

  # Check we have a valid Context hash.
  # Must contain a platform - all other
  # elements are optional
  class ContextHash
    def self.valid?(val)
      val.is_a? Hash &&
        val.has_key?("p")
    end
  end

  # Contract synonyms
  OptionPlatform = Or[Platform, nil]

  # Stores a width x height tuple. Used to express
  # screen resolution, app viewport etc
  class ViewDimensions

    attr_reader :width,
                :height

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
      nil
    end

    # Sets the view height
    #
    # Parameters:
    # +height+:: view height, a positive integer
    Contract PosInt => nil
    def height=(height)
      @height = height
      nil
    end

  end

  # Contract synonyms
  OptionViewDimensions = Or[ViewDimensions, nil]

  # Stores the Context which encapsulates an individual
  # Snowplow event.
  class Context < Payload

    @@default_platform = "pc"

    attr_reader :platform,
                :app_id,
                :screen_resolution,
                :viewport,
                :color_depth,
                :web_page

    # Constructor for a new event Context.
    # platform must be set in this constructor
    # because all Snowplow events must have a
    # platform.
    #
    # Parameters:
    # +platform+:: the device platform in which this
    #              Context is taking place. Defaults to pc
    # +app_id+:: the application ID
    # +screen_resolution+:: the user's screen resolution
    # +viewport+:: the screen space taken up by this app
    # +color_depth+:: screen's color depth
    # +web_page+:: the web page this Context occurred on
    # +time+:: the time to set this Context to
    Contract OptionPlatform, OptionString, OptionViewDimensions, OptionViewDimensions, OptionPosInt, OptionWebPage, OptionEpoch => Context
    def initialize(platform=@@default_platform,
                   app_id=nil,
                   screen_resolution=nil,
                   viewport=nil,
                   color_depth=nil,
                   web_page=nil,
                   freeze_time_at=nil
                   )
      @platform = platform
      @app_id = app_id
      @screen_resolution = screen_resolution
      @viewport = viewport
      @color_depth = color_depth
      @web_page = web_page
      @frozen_time = freeze_time_at
    end

    # Creates a copy of this Context with the
    # time modified as supplied
    #
    # Parameters:
    # +time+:: the time to set this Context to
    Contract Epoch => Context
    def at(time)
      self.dup.tap do |ctx| 
        ctx.frozen_time = time
      end
    end

    # Creates a copy of this Context with the
    # underlying web page given as supplied
    #
    # Parameters:
    # +web_page+:: the web page this Context occurred on
    Contract WebPage => Context
    def on(web_page)
      self.dup.tap do |ctx|
        ctx.web_page = web_page
      end
    end

    # Gets the current time in this Context.
    #
    # Returns either now, or the frozen time,
    # if this Context's time was frozen
    Contract => Epoch
    def time
      @frozen_time || Time.now
    end

    # Has the time of this Context been
    # frozen?
    #
    Contract => Boolean
    def time_frozen?
      !frozen_time.nil?
    end

    # Sets a point in time when this Context
    # was frozen. All events subsequently tagged
    # with this Context are timeed with
    # this "frozen time", rather than the time at
    # which this event was created in Ruby.
    #
    # Parameters:
    # +time+:: the time to set this Context to
    Contract Int => nil
    def freeze_time_at(time)
      @frozen_time = time
      nil
    end

    # Sets the WebPage on which this event is
    # occurring
    #
    # Parameters:
    # +web_page+:: the web page on which this
    #              event is occurring
    Contract WebPage => nil
    def web_page=(web_page)
      @web_page = web_page
      nil
    end

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

    # Setter for the application ID
    #
    # Parameters:
    # +app_id+:: the application ID
    Contract String => nil
    def app_id=(app_id)
      @app_id = app_id
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

    # Setter for screen's color depth
    #
    # Parameters:
    # +color_depth+:: screen's color depth
    Contract PosInt => nil
    def color_depth=(color_depth)
      @color_depth = color_depth
      nil
    end

    # Converts the current Context into a
    # payload compatible with the Snowplow
    # Tracker Protocol:
    # XXX
    #
    # Returns a Hash containing all the
    # name:value pairs. Individual values are
    # escaped as required by the Snowplow
    # Tracker Protocol
    Contract => ContextHash
    def to_payload_hash()
      super(
        
      )
    end

  end

  # Contract synonyms
  OptionContext = Or[Context, nil]

end
