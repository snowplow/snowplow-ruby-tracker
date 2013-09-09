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

end
