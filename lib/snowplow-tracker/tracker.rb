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

  class Tracker

    # Readers
    attr_reader :collectors,
                :encode_base64,
                :pinned_subject,
                :pinned_context
    # We'll add the setters manually with contracts

    # Constants
    @@default_encode_base64 = true

    # Contract synonyms
    CollectorOrCollectors = Or[Collector, Array[Collector]]
    OptionCollectorTagOrTags = Or[String, Array[String], nil]
    OptionSubject = Or[Subject, nil]
    OptionContext = Or[Context, nil]

    # Constructor for a new Snowplow Tracker.
    # Initialize it with one or more Collectors.
    #
    # Parameters:
    # +collectors+:: either a Collector, or an Array
    #                of Collectors =>
    Contract CollectorOrCollectors => Tracker
    def initialize(collectors)

      @collectors = Array(collectors) # Turn to array if single Collector
      @collector_hash = build_hash_of(@collectors)
      @encode_base64 = @@default_encode_base64
      
      nil
    end

    # Pin a given Context to all events fired subsequently.
    # Can still be overridden on a per-event basis.
    #
    # Parameters:
    # +context+:: the Context to pin to all subsequent events
    Contract Context => nil
    def pin_context(context)
      @pinned_context = context
      nil
    end

    # Pin a given Subject to all events fired subsequently.
    # Can still be overridden on a per-event basis.
    #
    # Parameters:
    # +subject+:: the Subject to pin to all subsequent events
    Contract Subject => nil
    def pin_subject(subject)
      @pinned_subject = subject
      nil
    end

    # Setter for the Array of Collectors available to
    # this Tracker.
    #
    # Parameters:
    # +collectors+:: either a Collector, or an Array
    #                of Collectors =>
    Contract CollectorOrCollectors => nil
    def collectors=(collectors)
      @collectors = Array(collectors)
      nil
    end

    # Setter for encode_base64 property i.e.
    # whether or not to base64 encode JSON
    # payloads
    #
    # Parameters:
    # +base64_encode+:: whether to base64 encode
    #                   or not
    Contract Bool => nil
    def base64_encode=(base64_encode)
      @base64_encode = base64_encode
      nil
    end

    # Track a Google Analytics-style custom structured event.
    #
    # +struct_event+:: the custom structured event
    # +subject+:: the optional Subject performing this event.
    #             Overrides any pinned Subject
    # +context+:: the optional Context in which this event
    #             takes place. Overrides any pinned Context
    #
    # Returns ??
    Contract StructEvent, OptionSubject, OptionContext => nil # TODO: fix return
    def track_struct_event(struct_event,
                           subject=@pinned_subject,
                           context=@pinned_context)

      nil # TODO: fix return
    end

    # Track a MixPanel- or KISSmetrics-style custom
    # unstructured event.
    #
    # +unstruct_event+:: the custom unstructured event
    # +subject+:: the optional Subject performing this event.
    #             Overrides any pinned Subject
    # +context+:: the optional Context in which this event
    #             takes place. Overrides any pinned Context
    #
    # Returns ??
    Contract UnstructEvent, OptionSubject, OptionContext => nil # TODO: fix return
    def track_unstruct_event(usntruct_event,
                             subject=@pinned_subject,
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
    # +subject+:: the optional Subject performing this event.
    #             Overrides any pinned Subject
    # +context+:: the optional Context in which this event
    #             takes place. Overrides any pinned Context
    #
    # Returns ??
    Contract WebPage, OptionSubject, OptionContext => nil # TODO: fix return
    def track_page_view(web_page,
                        subject=@pinned_subject,
                        context=@pinned_context)                    

      nil # TODO: fix return
    end

    # Track a sales order - referred to as an
    # ecommerce transaction in other Snowplow
    # trackers.
    #
    # +sales_order+:: the sales order to track,
    #                 including order line items
    # +subject+:: the optional Subject performing this event.
    #             Overrides any pinned Subject
    # +context+:: the optional Context in which this event
    #             takes place. Overrides any pinned Context
    Contract SalesOrder, OptionSubject, OptionContext => nil # TODO: fix return
    def track_sales_order(sales_order,
                          subject=@pinned_subject,
                          context=@pinned_context)                    

      nil # TODO: fix return
    end

    private

    # Helper to generate a hash of tag -> Collectors.
    # This is used when the user wants to send
    # events to a specific Collector or Collectors.
    #
    # Parameters:
    # +collectors+:: the Array of Collectors to
    #                build a hash from
    Contract Array[Collector] => Hash[String, Collector] # TODO: does this work?
    def Tracker.build_hash_of(collectors)
      collectors.map( |c| {
        { c.tag => = c }
      }
    end

  end
end
