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

  class ViewDimensions

    # Parameters:
    # +width+:: width of user's screen in pixels
    # +height+:: height of user's screen in pixels


    # Helper to convert a pair of view dimensions
    # (width and height) into a "heightxwidth"
    # String ready for Snowplow Tracker Protocol
    Contract ViewDimensions => String
    def stringify_dimensions(width, height)
      "#{width}x#{height}"
    end

  end

  class Tracker

    attr_reader :collector_uri,
                :platform,
                :encode_base64,
                :screen_resolution,
                :viewport,

    # We'll add the setters manually with contracts

    # Constants
    @@default_encode_base64 = true
    @@default_platform = "pc"

    # Constructor for a new Snowplow Tracker,
    # talking to a URI-based collector on the
    # given host.
    #
    # Parameters:
    # +args+:: hash containing either :host =>
    #          or :cf_subdomain =>
    Contract NewTrackerHash => Tracker
    def initialize(args)
      
      host = args["host"] || to_host(args["cf_subdomain"])
      @collector_uri = to_collector_uri(host)
    
      @platform = @@default_platform
      @encode_base64 = @@default_encode_base64
    end

    # Setter for encode_base64 property i.e.
    # whether or not to base64 encode JSON
    # payloads
    #
    # Parameters:
    # +base64_encode+:: whether to base64 encode
    #                   or not
    Contract Bool => nil
    def base64_encode=(base64_encode)
      @base64_encode = base64_encode
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

    private

    # Helper to generate the collector URI from
    # a collector hostname
    # Example:
    # as_collector_uri("snplow.myshop.com") => "http://snplow.myshop.com/i"
    #
    # Parameters:
    # +host+:: the host name of the collector
    #
    # Returns the collector URI
    Contract String => String
    def Snowplow.to_collector_uri(host)
      "http://#{host}/i"
    end

    # Helper to convert a CloudFront subdomain
    # to a collector hostname
    # Example:
    # to_host("f3f77d9def5") => "f3f77d9def5.cloudfront.net"
    #
    # Parameters:
    # +cf_subdomain+:: the CloudFront subdomain
    #
    # Returns the collector host
    Contract String => String
    def Snowplow.to_host
      "#{cf_subdomain}.cloudfront.net"
    end

  end
end
