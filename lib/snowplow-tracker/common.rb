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
  OptionString = Or[String, nil]
  OptionNum = Or[Num, nil]
  Epoch = Int

  # Validate is an integer
  class Int
    def self.valid?(val)
      val.is_a? Integer
    end
  end

  # Validate is a positive integer
  PosInt = And[Pos, Int]
  OptionPosInt = Or[PosInt, nil]

  # Payloadable contains helper
  # methods for escaping values
  # as part of a Snowplow payload
  class Payload

    # Skeleton for 
    # Must be overridden in a child class
    def to_payload()
      raise "to_payload() must be implemented in any Payload subclass"
    end

    # TODO

    # TODO

    # TODO
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
