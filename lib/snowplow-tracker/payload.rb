# Copyright (c) 2013-2021 Snowplow Analytics Ltd. All rights reserved.
#
# This program is licensed to you under the Apache License Version 2.0,
# and you may not use this file except in compliance with the Apache License Version 2.0.
# You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the Apache License Version 2.0 is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.

# Author:: Snowplow Analytics Ltd
# Copyright:: Copyright (c) 2013-2021 Snowplow Analytics Ltd
# License:: Apache License Version 2.0


require 'base64'
require 'json'
require 'net/http'
require 'contracts'

module SnowplowTracker
  # @private
  # Every`track_x_event` method creates a new Payload object. The Tracker then
  # uses the Payload instance methods to add properties to the Payload `@data`
  # hash. These properties form the raw event, after the completed hash is
  # given to the Emitter.
  class Payload
    include Contracts

    attr_reader :data

    Contract nil => Any
    def initialize
      @data = {}
    end

    Contract String, Or[String, Bool, Num, nil] => Or[String, Bool, Num, nil]
    # Add a single name-value pair to @data.
    def add(name, value)
      @data[name] = value if (value != '') && !value.nil?
    end

    Contract Hash => Hash
    # Add each name-value pair in a hash to @data.
    def add_hash(hash)
      hash.each { |key, value| add(key, value) }
    end

    Contract Maybe[Hash], Bool, String, String => Maybe[String]
    # Stringify a JSON and add it to @data.
    #
    # In practice, the JSON provided will be a SelfDescribingJson. This method
    # is used to add context to events, or for `track_self_describing_event`.
    # @see Tracker#track_unstruct_event
    # @see Tracker#finalise_payload
    def add_json(json, encode_base64, type_when_encoded, type_when_not_encoded)
      return if json.nil?

      stringified = JSON.generate(json)

      if encode_base64
        add(type_when_encoded, Base64.strict_encode64(stringified))
      else
        add(type_when_not_encoded, stringified)
      end
    end
  end
end
