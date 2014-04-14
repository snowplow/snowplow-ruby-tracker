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

  # A web page. Used as an Object
  # (page view) but also as Context
  # (page pings, ecommerce events etc).
  # Inherits from Entity.
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
    Contract URI,
             OptionString,
             OptionViewDimensions,
             OptionString => nil
    def initialize(uri,
                   title=nil,
                   size=nil,
                   charset=nil)
      @uri     = uri
      @title   = title
      @size    = size
      @charset = charset
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
