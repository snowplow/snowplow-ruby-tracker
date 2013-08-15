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

    # Constructor for a pair of view dimensions
    #
    # Parameters:
    # +width+:: width of user's screen in pixels
    # +height+:: height of user's screen in pixels
    Contract 

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
                :encode_base64,

    # We'll add the setters manually with contracts

    # Constants
    @@default_encode_base64 = true

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


  end
end
