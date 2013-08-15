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

  # Defines a Snowplow collector to send
  # events to
  class Collector

    attr_reader :endpoint_uri

    # Constructor for a new Snowplow Collector.
    #
    # Parameters:
    # +name+:: name of this collector. Can be used to
    #          decide which collector to send events to
    # +endpoint+:: hash defining the endpoint, containing
    #              either :host => or :cf_subdomain =>
    Contract String, CollectorEndpoint => Collector
    def initialize(name, endpoint)
      
      host = args["host"] || to_host(args["cf_subdomain"])
      @endpoint_uri = to_collector_uri(host)
    
      @platform = @@default_platform
      @encode_base64 = @@default_encode_base64
    end

    # TODO: add setters for endpoint using CloudFront or URI

  end

  # For private classes
  module Internal

    # Validate the hash passed to the constructor
    # of a new Collector
    class CollectorEndpoint
      def self.valid?(val)
        val.length == 1 &&
          (val.has_key? "uri" || val.has_key? "cf_subdomin")
      end
    end

  end
end