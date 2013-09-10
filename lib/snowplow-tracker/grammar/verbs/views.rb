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

  module Views

    include Protocol

    # Converts this Verb into a Hash representing its
    # event type, ready for adding to the payload.
    # Follows the Snowplow Tracker Protocol:
    #
    # https://github.com/snowplow/snowplow/wiki/snowplow-tracker-protocol
    #
    # Returns a VerbHash 
    Contract => VerbHash
    def as_hash()
      to_protocol([ 'e', 'pv', :raw ])
    end
    module_function :as_hash

    # Subject views a web page.
    #
    # WARNING: all the Web's tiers of caching mean
    # that relying on your web server to track
    # page views is almost always a BAD IDEA.
    #
    # Use the Snowplow JavaScript Tracker instead:
    # https://github.com/snowplow/snowplow-javascript-tracker
    #
    # Parameters:
    # +web_page+:: the WebPage the user is viewing
    # +modifiers+:: a Hash of modifiers. Can include custom Context
    #               and specific Collectors to send this event to
    #
    # Returns ??
    Contract WebPage, OptionModifierHash => Payload
    def views(web_page,
              modifiers={})


      nil # TODO: fix return
    end
    module_function :views

  end

end
