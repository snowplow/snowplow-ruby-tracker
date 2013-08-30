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

  # Contract synonyms
  Event = Or[StructEvent, UnstructEvent]
  OptionContext = Or[Context, nil]

  # The Subject of a Snowplow event.
  # Inherits from Entity
  class Subject < Entity

    attr_reader :ip_address,
                :business_user_id,
                :domain_user_id,
                :network_user_id,
                :pinned_context

    # Constructor for a new Subject.
    # All fields are optional
    #
    # Parameters:
    # +ip_address+:: user's IP address
    # +business_user_id+:: user's business-defined ID
    # +domain_user_id+:: user's ID stored by Snowplow
    #                    on a first-party cookie
    # +network_user_id+:: user's ID stored by Snowplow
    #                     on a third-party cookie
    Contract OptionString, OptionString, OptionString, OptionString => Subject
    def initialize(ip_address=nil, business_user_id=nil, domain_user_id=nil, network_user_id=nil)

      @ip_address = ip_address
      @business_user_id = business_user_id
      @domain_user_id = domain_user_id
      @network_user_id = network_user_id

      nil
    end

    # Sets the Subject's IP address
    #
    # Parameters:
    # +ip_address+:: the Subject's IP address
    Contract String => nil
    def ip_address=(ip_address)
      @ip_address = ip_address
    end

    # Sets the Subject's business user ID
    #
    # Parameters:
    # +user_id+:: the Subject's business user ID
    Contract String => nil
    def business_user_id=(user_id)
      @business_user_id = user_id
    end

    # Sets the Subject's domain user ID
    #
    # Parameters:
    # +user_id+:: the Subject's domain user ID
    Contract String => nil
    def domain_user_id=(user_id)
      @domain_user_id = user_id
    end

    # Sets the Subject's network user ID.
    #
    # Note: it may be hard to acquire this
    # on the server-side.
    #
    # Parameters:
    # +user_id+:: the Subject's network user ID
    def network_user_id=(user_id)
      @network_user_id = user_id
    end
    
    # Pin the given Context to this Subject.
    # Can still be overridden on a per-event basis.
    #
    # Parameters:
    # +context+:: the Context to pin to all subsequent events
    Contract Context => nil
    def pin_context(context)
      @pinned_context = context
      nil
    end

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
    def performs_event(event,
                       context=@pinned_context)

      nil # TODO: fix return
    end

    # Track a page view event.
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
    def views_web_page(web_page,
                       context=@pinned_context)

      nil # TODO: fix return
    end

    # Track a sales order - referred to as an
    # ecommerce transaction in other Snowplow
    # trackers.
    #
    # +sales_order+:: the sales order to track,
    #                 including order line items
    # +context+:: the optional Context in which this event
    #             takes place. Overrides any pinned Context
    Contract SalesOrder, OptionContext => nil # TODO: fix return
    def places_order(sales_order,
                     context=@pinned_context)                    

      nil # TODO: fix return
    end

  end
end
