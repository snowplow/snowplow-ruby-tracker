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

require 'uri'
require 'base64'

require 'contracts'
include Contracts

module Snowplow

  # This class validates a ProtocolTuple.
  #
	# A ProtocolTuple can take two forms - either:
  # 1. [ key, value ] - or:
  # 2. [ key, value, encoding ]
  #
  # Supported encoding_modifiers are :escape
  # (the default if not set), :raw and :base64
  class ProtocolTuple

    @@encodings = Set.new(:raw, :escape, :base64)

    # Validate this is an ElementTuple
    def self.valid?(val)
      val.is_a? Array &&
        (val.length == 2 ||
        (val.length == 3 && @@encodings.include?(val[2])))
    end

  end

	# Entities (Subjects and Objects), Verbs and
  # Context all mix-in Grammar.
  #
  # Grammar contains helper methods for
  # constructing a Hash which follows the Snowplow
  # Tracker Protocol.
  #
  # Includes methods to URL-escape and Base64-encode
  # the individual fields.
  module Grammar

    # Converts an Array of ProtocolTuples to a Hash,
    # ready for inserting in our payload. Called
    # by Grammar's sub-classes.
    #
    # Parameters:
    # +tuples+:: an Array of ProtocolTuples
    #
    # Returns a single Hash of all key => value
    # pairs. Could still be empty, {}
    Contract Array[ProtocolTuple] => OptionHash
    def to_protocol(*tuples)
      hashes = tuples.map( |t| to_unary_hash(t) )
      {}.merge(hashes)
    end
    module_function :to_protocol

    private

    # Converts a protocol "tuple" to a
    # key => value pair.
    #
    # Protocol tuples take two forms - either:
    # 1. [ key, value ] - or:
    # 2. [ key, value, encoding_modifier ]
    #
    # Parameters:
    # +tuple+:: the protocol tuple to convert
    #           into a key => value pair
    #
    # Returns a single key => value pair
    # in a Hash
    Contract ProtocolTuple => UnaryHash
    def to_unary_hash(tuple)

      encoding = case tuple.length
                 when 2
                   :escape # Default
                 when 3
                   tuple[2]
                 else # Should never happen
                   raise Snowplow::Exceptions::ContractFailure.new
                 end

      # Now safe to get these
      key = tuple[0]
      value = tuple[1]

      # Return the appropriate { key => value }
    	case encoding
      when :escape
        add(key, value)
      when :raw
        addRaw(key, value)
      when :base64
        addBase64(key, value)
      else # Should never happen
        raise Snowplow::Exceptions::ContractFailure.new
      end
    end

    # Creates a Hash consisting of a single
    # key => value pair if the value is not
    # nil. The value is URL-encoded.
    #
    # Parameters:
    # +key+:: the key for this pair
    # +value+:: the value for this pair
    #
    # Returns a Hash of a single key => value
    # pair, or {}
    Contract String, OptionString => OptionUnaryHash
    def add(key, value)
      if value.nil?
        {}
      else
        { key => escape(value) }
      end
    end

    # Creates a Hash consisting of a single
    # key => value pair if the value is not
    # nil. addRaw because the value is not
    # URL-encoded.
    #
    # Parameters:
    # +key+:: the key for this pair
    # +value+:: the value for this pair
    #
    # Returns a Hash of a single key => value
    # pair, or {}
    Contract String, OptionString => OptionUnaryHash
    def addRaw(key, value)
      if value.nil?
        {}
      else
        { key => value }
      end
    end

    # Creates a Hash consisting of a single
    # key => value pair if the value is not
    # nil. addBase64 because the value is
    # URL-safe-Base64-encoded.
    #
    # Parameters:
    # +key+:: the key for this pair
    # +value+:: the value for this pair
    #
    # Returns a Hash of a single key => value
    # pair, or {}
    Contract String, OptionString => OptionUnaryHash
    def addBase64(key, value)
      if value.nil?
        {}
      else
        { key => base64(value) }
      end
    end

    # Wrapper around a URL-safe escape
    # aka encode.
    #
    # Parameters:
    # +str+:: the string to URL-escape
    #
    # Returns the URL-escaped string
    Contract String => String
    def escape(str)
      URI.escape(str, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    end

    # Wrapper around a URL-safe Base64
    # encode.
    #
    # Parameters:
    # +str+:: the string to Base64-encode
    #
    # Returns the Base64-encoded string
    Contract String => String
    def base64(str)
      Base64.urlsafe_encode64(str)
    end

  end

end
