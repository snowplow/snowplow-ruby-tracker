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

  # A sales order, aka an ecommerce transaction.
  # Fields follow Google Analytics closely.
  # Is the Direct Object of a place Transaction event.
  # Inherits from Entity.
  class Transaction < Entity

    attr_reader :order_id, 
                :affiliation,
                :total,
                :tax,
                :shipping,
                :city,
                :state,
                :country,
                :items

    # Constructor for an ecommerce Transaction.
    #
    # TODO
    Contract String,
             OptionString,
             Num,
             Num,
             Num,
             OptionString,
             OptionString,
             OptionString,
             Or[TransactionItem, TransactionItems]
             => nil
    def initialize(order_id, 
                   affiliation=nil,
                   total,
                   tax,
                   shipping,
                   city=nil,
                   state=nil,
                   country=nil,
                   items)

      @order_id    = order_id
      @affiliation = affiliation
      @total       = total
      @tax         = tax
      @shipping    = shipping
      @city        = city
      @state       = state
      @country     = country
      @items       = Array(items) # To array if not already
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
        [ 'tr_id', @order_id    ],
        [ 'tr_af', @affiliation ],
        [ 'tr_tt', @total       ],
        [ 'tr_tx', @tax         ],
        [ 'tr_sh', @shipping    ],
        [ 'tr_ci', @city        ],
        [ 'tr_st', @state       ],
        [ 'tr_co', @country     ] # Note the transaction items are not included in the Hash
      )
    end

  end

end
