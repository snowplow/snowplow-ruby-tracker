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

  # A MixPanel- or KISSmetrics-style custom
  # unstructured event, consisting of a name
  # and envelope of arbitrary name:value pairs
  # (represented as a Ruby hash).
  # Inherits from Entity.
  class UnstructEvent < Entity

    attr_reader :name,
                :properties

    # Constructor for a new custom unstructured event
    #
    # Parameters:
    # +name+:: the name of the event
    # +properties+:: the properties of the event
    Contract String, Hash => nil
    def initialize(name,
                   properties)
      @name       = name
      @properties = properties
      nil
    end

    # Converts this Object into a Hash of all its
    # properties, ready for adding to the payload.
    # Follows the Snowplow Tracker Protocol:
    #
    # https://github.com/snowplow/snowplow/wiki/snowplow-tracker-protocol
    #
    # Returns the Hash of all this entity's properties
    Contract => OptionHash
    def as_hash()
      to_protocol(
        [ 'ue_na', @name       ],
        [ 'ue_pr', @properties ], # We add both versions - the Tracker can decide which to use
        [ 'ue_px', @properties, :base64 ]
      )
    end

  end

end
