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

  # A sales order, aka an ecommerce transaction.
  # Is the Direct Object of a track_sales_order event.
  # Inherits from Entity
  class SalesOrder < Entity

Log ecommerce transaction metadata
   *
   * @param string orderId 
   * @param string affiliation 
   * @param string total 
   * @param string tax 
   * @param string shipping 
   * @param string city 
   * @param string state 
   * @param string country 

   items

  end

  # A line item within a sales order. Can contain multiple
  # units of the same SKU.
  # Inherits from Entity
  class SalesOrderItem < Entity

Log ecommerce transaction item
   *
   * @param string orderId
   * @param string sku
   * @param string name
   * @param string category
   * @param string price
   * @param string quantity


  end 

  # A Google Analytics-style custom structured event.

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

    Contract String, String, OptionString, OptionString, OptionNum, OptionSubject, OptionContext => nil # TODO: fix return

struct_event(category,
                           action,
                           label=nil,
                           property=nil,
                           value=nil,


    # A MixPanel- or KISSmetrics-style custom
    # unstructured event, consisting of a name
    # and envelope of arbitrary name:value pairs
    # (represented as a Ruby hash).

    Contract String, Hash, OptionSubject, OptionContext => nil # TODO: fix return
    def track_unstruct_event(name,
                             properties,


    # +name+:: the name of the event
    # +properties+:: the properties of the event


  # A web page. Used variously as a
  # Direct Object (page view),
  # Prepositional Object (page ping)
  # or as Context (ecommerce events).
  # Inherits from Entity
  class WebPage < Entity

    attr_reader :uri,
                :title

    # Constructor for a new WebPage.
    # The URI of the WebPage must be set.
    #
    # Parameters:
    # +uri+:: URI of this WebPage
    # +title+:: title of this WebPage (i.e. <TITLE>
    #           or customized version of same)
    Contract URI, OptionString => WebPage
    def initialize(uri, title=nil)

      @uri = uri
      @title = title

      nil
    end

    # Sets the WebPage's URI
    #
    # Parameters:
    # +uri+:: URI of this WebPage
    Contract URI => nil
    def uri=(uri)
      @uri = uri
      nil
    end

    # Sets the WebPage's title
    Contract String => nil
    def title=(title)
      @title = title
      nil
    end

  end

  # Contract synonyms
  OptionWebPage = Or[WebPage, nil]

end