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

  # The Subject of a Snowplow event.
  # Note that Snowplow currently has a limitation where the Subject
  # of an event must be an Entity of type User.
  module Verbs

    # Contract synonyms
    Event = Or[StructEvent, UnstructEvent]

    # Subject performs a custom event. Could be either:
    # 1. A Google Analytics-style custom structured event, or:
    # 2. A MixPanel- or KISSmetrics-style custom unstructured event
    #
    # +event+:: the custom structured or unstructured event
    # +context+:: the optional Context in which this event
    #             takes place. Overrides any pinned Context
    #
    # Returns ??
    Contract Event, OptionContext => nil # TODO: fix return
    def performs(event,
                 context)

      # Switch based on type of event
      if event.is_a? StructEvent
        performs_struct_event(event, context)
      elsif event.is_a? UnstructEvent
        performs_unstruct_event(event, context)
      else # Should never happen thanks to Contracts
        raise Snowplow::Exceptions::ContractFailure.new
      end
    end

    # Subject views a web page.
    #
    # WARNING: all the Web's tiers of caching mean
    # that relying on your web server to track
    # page views is almost always a BAD IDEA.
    # Use the Snowplow JavaScript Tracker instead:
    # https://github.com/snowplow/snowplow-javascript-tracker
    #
    # +web_page+:: the WebPage the user is viewing
    # +context+:: the optional Context in which this event
    #             takes place. Overrides any pinned Context
    #
    # Returns ??
    Contract WebPage, OptionContext => nil # TODO: fix return
    def views(web_page,
              context)

      nil # TODO: fix return
    end

    # Subject places a sales order - referred to as an
    # ecommerce transaction in other Snowplow trackers.
    #
    # +sales_order+:: the sales order to track,
    #                 including order line items
    # +context+:: the optional Context in which this event
    #             takes place. Overrides any pinned Context
    Contract SalesOrder, OptionContext => nil # TODO: fix return
    def places(sales_order,
               context)                    

      nil # TODO: fix return
    end

    private

    # Subject performs a Google Analytics-style custom structured event.
    # Procedure is private so public API can stick to using the cleaner
    # performs() procedure
    #
    # +event+:: the custom structured event
    # +context+:: the optional Context in which this event
    #             takes place. Overrides any pinned Context
    #
    # Returns ??
    Contract StructEvent, OptionContext => nil # TODO: fix return
    def performs_struct_event(event,
                 context)

      nil # TODO: fix return
    end

    # Subject performs a MixPanel- or KISSmetrics-style custom unstructured event.
    # Procedure is private so public API can stick to using the cleaner
    # performs() procedure
    #
    # +event+:: the custom unstructured event
    # +context+:: the optional Context in which this event
    #             takes place. Overrides any pinned Context
    #
    # Returns ??
    Contract UnstructEvent, OptionContext => nil # TODO: fix return
    def performs_unstruct_event(event,
                 context)

      nil # TODO: fix return
    end

  end
end
