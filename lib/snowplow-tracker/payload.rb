# Copyright (c) 2013-2014 Snowplow Analytics Ltd. All rights reserved.
#
# This program is licensed to you under the Apache License Version 2.0,
# and you may not use this file except in compliance with the Apache License Version 2.0.
# You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the Apache License Version 2.0 is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.

# Author:: Alex Dean, Fred Blundun (mailto:support@snowplowanalytics.com)
# Copyright:: Copyright (c) 2013-2014 Snowplow Analytics Ltd
# License:: Apache License Version 2.0

require 'base64'
require 'json'
require 'net/http'
require 'contracts'

module SnowplowTracker
  class Payload
    include Contracts

    attr_reader :context

    Contract nil => Any
    def initialize
      @context = {}
    end

    # Add a single name-value pair to @context
    #
    Contract String, Or[String, Bool, Num, nil] => Or[String, Bool, Num, nil]
    def add(name, value)
      @context[name] = value if (value != '') && !value.nil?
    end

    # Add each name-value pair in hash to @context
    #
    Contract Hash => Hash
    def add_hash(hash)
      hash.each { |key, value| add(key, value) }
    end

    # Stringify a JSON and add it to @context
    #
    Contract Maybe[Hash], Bool, String, String => Maybe[String]
    def add_json(hash, encode_base64, type_when_encoded, type_when_not_encoded)
      return if hash.nil?

      hash_string = JSON.generate(hash)

      if encode_base64
        add(type_when_encoded, Base64.strict_encode64(hash_string))
      else
        add(type_when_not_encoded, hash_string)
      end
    end
  end
end
