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

  module Places

    include Protocol

    # Defines the valid Transaction Symbols
    class TransactionSymbol

      @@valid_transactions = Set::[](:tr, :ti)

      def self.valid?(val)
        val.is_a? Symbol &&
          @@valid_transactions.include?(val)
      end
    end

    # Converts this Verb into a Hash representing its
    # event type, ready for adding to the payload.
    # Follows the Snowplow Tracker Protocol:
    #
    # https://github.com/snowplow/snowplow/wiki/snowplow-tracker-protocol
    #
    # Parameters:
    # +tr_symbol+:: whether the Verb is referring to placing
    #               a transaction, or recording a transaction
    #               item within the transaction. Nasty but
    #               needed to handle Snowplow's Tracker
    #               Protocol (which needs to change).
    #
    # Returns a VerbHash 
    Contract TransactionSymbol => VerbHash
    def as_hash(tr_symbol)
      to_protocol([ 'e', tr_symbol.to_s, :raw ])
    end
    module_function :as_hash

    # Subject places an ecommerce transaction.
    #
    # Parameters:
    # +sales_order+:: the sales order to track,
    #                 including order line items
    # +modifiers+:: a Hash of modifiers. Can include custom Context
    #               and specific Collectors to send this event to
    Contract SalesOrder, OptionModifierHash => nil # TODO: fix return
    def places(sales_order,
               modifiers={})                 

      nil # TODO: fix return
    end
    module_function :places

  end

end
