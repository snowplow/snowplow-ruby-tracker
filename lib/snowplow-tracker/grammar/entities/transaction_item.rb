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

  # A line item within a sales order: one or more units
  # of a single SKU.
  # Fields follow Google Analytics closely.  
  # Inherits from Entity.
  class TransactionItem < Entity

    attr_reader :sku,
                :name,
                :category,
                :price,
                :quantity

    # Constructor for a TransactionItem, i.e. a line
    # item within a Transaction. A line item is
    # defined as one or more units of a single SKU.
    #
    # Parameters:
    # +sku+:: The stock keeping unit for this item
    # +name+:: The name of this item
    # +category+:: The category this item belongs to
    # +price+:: The total price for all units of this item
    # +quantity+:: The number of units of this item
    Contract OptionString,
             OptionString,
             OptionString,
             Num,
             Int => nil
    def initialize(sku=nil,
                   name=nil,
                   category=nil,
                   price,
                   quantity)

      if sku.nil? && name.nil? raise UnidentifiedTransactionItem end

      @sku      = sku
      @name     = name
      @category = category
      @price    = price
      @quantity = quantity
      nil
    end

    # Converts this Object into a Hash of all its
    # properties, ready for adding to the payload.
    # Follows the Snowplow Tracker Protocol:
    #
    # https://github.com/snowplow/snowplow/wiki/snowplow-tracker-protocol
    #
    # Note: the Snowplow Tracker Protocol expects
    # Transaction Items to be transmitted with the
    # Transaction's Order ID and Currency. We have
    # to pass these in as parameters:
    #
    # Parameters:
    # +order_id+:: Order ID for this transaction
    # +currency+:: Currency code for this transaction
    #
    # Returns the Hash of all this entity's properties
    Contract => OptionHash
    def as_hash(order_id, currency)
      to_protocol(
        [ 'ti_id', order_id  ],
        [ 'ti_sk', @sku      ],
        [ 'ti_na', @name     ],
        [ 'ti_ca', @category ],
        [ 'ti_pr', @price    ],
        [ 'ti_cu', currency  ],
        [ 'ti_qu', @quantity ]
      )
    end

  end 

  # Contract synonyms
  TransactionItems = Array[TransactionItem]

end
