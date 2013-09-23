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

    # Readers
    attr_reader :collectors,
                :encode_base64,
                :context,
                :queue
    # We'll add the setters manually with contracts

    # Constants
    @@default_encode_base64 = true

    # Constructor for a new Snowplow Tracker.
    # Initialize it with one or more Collectors.
    #
    # Parameters:
    # +collectors+:: either a Collector, or an Array
    #                of Collectors
    # +encode_base64+:: whether JSONs should be
    #                   Base64-encoded or not
    Contract Or[Collector, Collectors] => Tracker
    def initialize(collectors, encode_base64=@@default_encode_base64)

      @collectors = Array(collectors) # To array if not already
      @collector_hash = build_hash_of(@collectors)
      @encode_base64 = encode_base64
      @queue = [] # No events to track yet

      nil
    end

    # Setter for the Array of Collectors available to
    # this Tracker.
    #
    # Parameters:
    # +collectors+:: either a Collector, or an Array
    #                of Collectors =>
    Contract Or[Collector, Collectors] => nil
    def collectors=(collectors)
      @collectors = Array(collectors)
      nil
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

    # Allows a Context to be "pinned" to this
    # Tracker - i.e. all further events will
    # have this Context attached to them
    #
    # Parameters:
    # +context+:: the Context to pin to this
    #             Tracker
    Contract Context => nil
    def pin_context(context)
      @context = context
      nil
    end

    # 

    private

    # Helper to generate a hash of tag -> Collectors.
    # This is used when the user wants to send
    # events to a specific Collector or Collectors.
    #
    # Parameters:
    # +collectors+:: the Array of Collectors to
    #                build a hash from
    Contract Collectors => Hash[CollectorTag, Collector] # TODO: does this work?
    def self.build_hash_of(collectors)
      collectors.map( |c| {
        { c.tag => = c }
      }
    end

  end
end
