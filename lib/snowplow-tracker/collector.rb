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

    attr_accessor :tag
    attr_reader   :endpoint_uri, # writer implemented manually
                  :http_method   # writer implemented manually
    # We'll add the setters manually with contracts

    # Constructor for a new Snowplow Collector. Supports
    # 1) Snowplow Collectors on any domain (:host => x)
    # 2) Snowplow CloudFront Collectors on any CloudFront
    #    subdomain (:cf => x)
    #
    # Parameters:
    # +tag+:: name of this Collector. Can be used to
    #         decide which Collector to send events to
    # +endpoint+:: hash defining the endpoint, containing
    #              either :host => or :cf =>
    Contract String, CollectorEndpoint, CollectorHttpMethod => Collector
    def initialize(tag, endpoint, http_method=:get)
      @tag = tag
      @http_method = http_method

      host = endpoint["host"] || to_host(endpoint["cf"])
      set_host_endpoint(host)
    end

    # Manually set the Collector's endpoint to CloudFront
    #
    # Parameters:
    # +cf_subdomain+:: the CloudFront sub-domain for
    #                  the collector
    Contract String => nil
    def set_cf_endpoint(cf_subdomain)
      @endpoint_uri = to_endpoint_uri(to_host(cf_subdomain))
    end

    # Manually set the Collector's endpoint to any host
    #
    # Parameters:
    # +host+:: the hostname on which this Collector is running
    Contract String => nil
    def set_host_endpoint(host)
      @endpoint_uri = to_endpoint_uri(host)
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
    def Collector.to_endpoint_uri(host)
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
    def Collector.to_host(cf_subdomain)
      "#{cf_subdomain}.cloudfront.net"
    end

  end

  # For private classes
  module Internal

    # Validates the hash passed to the constructor
    # of a new Collector
    class CollectorEndpoint
      def self.valid?(val)
        val.is_a? Hash &&
          val.length == 1 &&
          (val.has_key? "uri" || val.has_key? "cf_subdomin")
      end
    end

    # Validates the HTTP method used to send to
    # the Collector
    class CollectorHttpMethod
      @@valid_methods = Set.new(:get)

      def self.valid?(val)
        @@valid_methods.include?(val)
      end
    end
  end

end
