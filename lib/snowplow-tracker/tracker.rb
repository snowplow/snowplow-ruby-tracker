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


  class Tracker

    attr_read :collector_uri, :platform, :encode_base64 
    # We will handle the setters manually with validation

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

    # Setter for encode_base64 property
    # 
    Contract Bool => nil
    def set_platform(platform)
      @platform = platform
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