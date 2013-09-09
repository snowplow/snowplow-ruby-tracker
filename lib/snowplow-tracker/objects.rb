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

require 'contracts'
include Contracts

module Snowplow

  # A line item within a sales order: one or more units
  # of a single SKU.
  # Fields follow Google Analytics closely.  
  # Inherits from Entity
  class TransactionItem < Entity

    attr_reader :order_id,
                :sku,
                :name,
                :category,
                :price,
                :quantity

    # Constructor for a TransactionItem, i.e. a line
    # item within a Transaction
    #
    # TODO
    Contract String, OptionString, OptionString, OptionString, Num, Int => TransactionItem
    def initialize(order_id,
                   sku=nil,
                   name=nil,
                   category=nil,
                   price,
                   quantity)

      # TODO: check at least one of sku and name is set

      @order_id = order_id
      @sku      = sku
      @name     = name
      @category = category
      @price    = price
      @quantity = quantity
    end

    # Converts this Object into a Hash of all its
    # properties, ready for adding to the payload.
    # Follows the Snowplow Tracker Protocol:
    #
    # https://github.com/snowplow/snowplow/wiki/snowplow-tracker-protocol
    #
    # Returns the Hash of all this entity's properties
    Contract => OptionHash
    def to_protocol()
      super(
        [ 'ti_id', @order_id ],
        [ 'ti_sk', @sku      ],
        [ 'ti_na', @name     ],
        [ 'ti_ca', @category ],
        [ 'ti_pr', @price    ],
        [ 'ti_qu', @quantity ]
      )
    end

  end 

  # Contract synonyms
  TransactionItems = Array[TransactionItem]

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

    # Constructor for a Transaction, i.e. an ecommmerce
    # transaction
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
             => Transaction
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
    end

    # Converts this Object into a Hash of all its
    # properties, ready for adding to the payload.
    # Follows the Snowplow Tracker Protocol:
    #
    # https://github.com/snowplow/snowplow/wiki/snowplow-tracker-protocol
    #
    # Returns the Hash of all this entity's properties
    Contract => OptionHash
    def to_protocol()
      super(
        [ 'tr_id', @order_id    ],
        [ 'tr_af', @affiliation ],
        [ 'tr_tt', @total       ],
        [ 'tr_tx', @tax         ],
        [ 'tr_sh', @shipping    ],
        [ 'tr_ci', @city        ],
        [ 'tr_st', @state       ],
        [ 'tr_co', @country     ]
      )
    end

  end

  # A custom structured event.
  # Fields follow Google Analytics closely.  
  # Inherits from Entity
  class StructEvent < Entity

    attr_reader :category,
                :action,
                :label,
                :property,
                :value

    # Constructor for a new custom structured event
    #
    # +category+:: the name you supply for the group of
    #              objects you want to track
    # +action+:: a string that is uniquely paired with each
    #            category, and commonly used to define the
    #            type of user interaction for the object
    # +label+:: an optional string to provide additional
    #           dimensions to the event data
    # +property+:: an optional string describing the object
    #              or the action performed on it. This might
    #              be the quantity of an item added to basket
    # +value+:: an optional value that you can use to provide
    #           numerical data about the user event
    Contract String,
             String,
             OptionString,
             OptionString,
             OptionNum
             => StructEvent
    def initialize(category,
                   action,
                   label=nil,
                   property=nil,
                   value=nil)

      @category = category
      @action   = action
      @label    = label
      @property = property
      @value    = value
    end

    # Converts this Object into a Hash of all its
    # properties, ready for adding to the payload.
    # Follows the Snowplow Tracker Protocol:
    #
    # https://github.com/snowplow/snowplow/wiki/snowplow-tracker-protocol
    #
    # Returns the Hash of all this entity's properties
    Contract => OptionHash
    def to_protocol()
      super(
        [ 'se_ca', @category ],
        [ 'se_ac', @action   ],
        [ 'se_la', @label    ],
        [ 'se_pr', @property ],
        [ 'se_va', @value    ]
      )
    end

  end

  # A MixPanel- or KISSmetrics-style custom
  # unstructured event, consisting of a name
  # and envelope of arbitrary name:value pairs
  # (represented as a Ruby hash).
  # Inherits from Entity  
  class UnstructEvent < Entity

    attr_reader :name,
                :properties

    # Constructor for a new custom unstructured event
    #
    # +name+:: the name of the event
    # +properties+:: the properties of the event
    Contract String, Hash => UnstructEvent
    def initialize(name,
                   properties)
      @name       = name
      @properties = properties
    end

    # Converts this Object into a Hash of all its
    # properties, ready for adding to the payload.
    # Follows the Snowplow Tracker Protocol:
    #
    # https://github.com/snowplow/snowplow/wiki/snowplow-tracker-protocol
    #
    # Returns the Hash of all this entity's properties
    Contract => OptionHash
    def to_protocol()
      super(
        [ 'ue_na', @name       ],
        [ 'ue_pr', @properties ], # We add both versions - the Tracker can decide which to use
        [ 'ue_px', @properties, :base64 ]
      )
    end

  end

  # Contract synonyms
  Event = Or[StructEvent, UnstructEvent]

  # A web page. Used as an Object
  # (page view) but also as Context
  # (page pings, ecommerce events etc).
  # Inherits from Entity
  class WebPage < Entity

    attr_reader :uri,
                :title,
                :size,
                :charset

    # Constructor for a new WebPage.
    # The URI of the WebPage must be set.
    #
    # Parameters:
    # +uri+:: URI of this WebPage
    # +title+:: title of this WebPage (i.e. <TITLE>
    #           or customized version of same)
    Contract URI, OptionString, OptionViewDimensions, OptionString => WebPage
    def initialize(uri,
                   title=nil,
                   size=nil,
                   charset=nil)
      @uri     = uri
      @title   = title
      @size    = size
      @charset = charset
    end

    # Converts this Object into a Hash of all its
    # properties, ready for adding to the payload.
    # Follows the Snowplow Tracker Protocol:
    #
    # https://github.com/snowplow/snowplow/wiki/snowplow-tracker-protocol
    #
    # Returns the Hash of all this entity's properties
    Contract => OptionHash
    def to_protocol()
      super(
        [ 'url',  @uri     ], # Note url not uri
        [ 'page', @title   ],
        [ 'ds',   @size    ],
        [ 'cs',   @charset ]
      )
    end

  end

  # Contract synonyms
  OptionWebPage = Or[WebPage, nil]

end
