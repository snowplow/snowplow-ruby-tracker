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

  # Common contract synonyms
  Epoch = Int
  OptionString = Or[String, nil]
  OptionNum = Or[Num, nil]
  OptionHash = Or[Hash, {}] # Note not nil

  # Validate is an Integer
  class Int
    def self.valid?(val)
      val.is_a? Integer
    end
  end

  # Validate is a positive integer
  PosInt = And[Pos, Int]
  OptionPosInt = Or[PosInt, nil]

  # Validate is a Hash with single-element
  class UnaryHash
    def self.valid?(val)
      val.is_a? Hash &&
        val.length == 1
    end
  end

  # More aliases
  OptionUnaryHash = Or[UnaryHash, {}]

  # Stores a width x height tuple. Used to express
  # screen resolution, app viewport etc
  class ViewDimensions

    attr_reader :width,
                :height

    # Constructor for a pair of view dimensions
    #
    # Parameters:
    # +width+:: width of user's screen in pixels
    # +height+:: height of user's screen in pixels
    Contract PosInt, PosInt => ViewDimensions
    def initialize(width, height)
      @width = width
      @height = height
    end

    # String representation of these
    # view dimensions, in the format of the
    # Snowplow Tracker Protocol
    #
    # Returns "heightxwidth"
    Contract => String
    def to_s
      "#{@width}x#{@height}"  
    end

    # Sets the view width
    #
    # Parameters:
    # +width+:: view width, a positive integer
    Contract PosInt => nil
    def width=(width)
      @width = width
      nil
    end

    # Sets the view height
    #
    # Parameters:
    # +height+:: view height, a positive integer
    Contract PosInt => nil
    def height=(height)
      @height = height
      nil
    end

  end

  # Contract synonyms
  OptionViewDimensions = Or[ViewDimensions, nil]

  # Payload contains helper
  # methods for escaping values
  # as part of a Snowplow payload
  class Payload

    # Converts a set of key => value
    # pairs to a Hash, ready for
    # inserting in our payload. Called
    # by Payload's sub-classes to generate
    # their payload Hash
    #
    # Parameters:
    # +pairs+:: an Array of key => value
    #           pairs and {}s
    #
    # Returns a single Hash of all key => value
    # pairs. Could still be empty, {}
    Contract Array[OptionUnaryHash] => OptionHash
    def to_protocol(*pairs)
      {}.merge(pairs)
    end

    private

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
    Contract OptionKey, String => OptionUnaryHash
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
    Contract OptionKey, String => OptionUnaryHash
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
    Contract OptionKey, String => OptionUnaryHash
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

  # Parent class for any entity which is the Subject
  # or Object (Direct, Indirect, Prepositional) of a
  # Snowplow event.
  #
  # Inherits from Payload, as all entities must be
  # convertable to payload.
  class Entity < Payload

  end

end
