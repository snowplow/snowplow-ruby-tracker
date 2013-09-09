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

  # Check we have a valid Context Hash.
  #
  # Must contain:
  # 1. platform ("p")
  # 2. time ("dtm")
  #
  # All other elements are optional
  ContextHash = ({ :p => String, :dtm => String })

  # Stores the Context which encapsulates an individual
  # Snowplow event.
  # We let Context be much more mutable than our Entities,
  # because this fits the real-world better: context
  # slowly mutates as events happen.
  class Context < GrammarElement

    attr_reader :platform,
                :app_id,
                :resolution,
                :viewport,
                :color_depth,
                :timezone,
                :language,
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
    # +resolution+:: the user's screen resolution
    # +viewport+:: the screen space taken up by this app
    # +color_depth+:: screen's color depth
    # +web_page+:: the web page this Context occurred on
    # +time+:: the time to set this Context to
    Contract OptionPlatform, OptionString, OptionViewDimensions, OptionPosInt, OptionString, OptionWebPage, OptionEpoch => Context
    def initialize(platform=Platform.default,
                   app_id=nil,
                   resolution=nil,
                   viewport=nil,
                   color_depth=nil,
                   web_page=nil,
                   freeze_time_at=nil
                   )
      @platform = platform
      @app_id = app_id
      @resolution = resolution
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
    def resolution=(view_dimensions)
      @resolution = view_dimensions
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
    def to_protocol()
      super(
        [ 'p', platform ], # Must be set
        [ 'dtm', time(), :raw ], # Must be set
        [ 'vp', viewport, :raw ],
        [ 'res', resolution, :raw ],
        [ 'cd', color_depth, :raw ],
        [ 'p', platform ],
        [ 'aid', app_id ],
        [ 'lang', language ]

        # TODO: how do we get webpage in here too?
      )
    end

  end

  # Contract synonyms
  OptionContext = Or[Context, nil]

end
