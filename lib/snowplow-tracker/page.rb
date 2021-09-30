# Copyright (c) 2013-2014 Snowplow Analytics Ltd. All rights reserved.
#
# This program is licensed to you under the Apache License Version 2.0,
# and you may not use this file except in compliance with the Apache License Version 2.0.
# You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the Apache License Version 2.0 is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.

# Author:: Alex Dean, Fred Blundun (mailto:support@snowplowanalytics.com)
# Copyright:: Copyright (c) 2013-2014 Snowplow Analytics Ltd
# License:: Apache License Version 2.0


require 'contracts'

module SnowplowTracker
  # If the Ruby tracker is incorporated into a website server, the events
  # tracked will describe user activity on specific webpages. Knowing on which
  # page an event occurred can be very valuable.
  #
  # Add page URL, page title and referrer URL to any event by adding a Page
  # object to any {Tracker} `#track_x_event` method call.
  #
  # Page parameters are saved into the tracked event as part of the 'atomic'
  # event properties, which have their own column in the eventual events table.
  # For example, a Page's `page_url` parameter will be sent as `url` in the
  # raw event payload, ending up in the `page_url` column.
  #
  #
  # @note For {Tracker#track_page_view}, properties set in the Page object will
  #   override those properties given as arguments.
  class Page
    include Contracts

    # @return [Hash] the stored page properties
    attr_reader :details

    Contract KeywordArgs[page_url: Maybe[String], page_title: Maybe[String], referrer: Maybe[String]] => Any
    # Create a Page object for attaching page properties to events.
    #
    # Page properties will directly populate the event's `page_url`, `page_title` and `referrer` parameters.
    #
    # @example Creating a Page
    #   Page.new(page_url: 'http://www.example.com/second-page',
    #            page_title: 'Example title',
    #            referrer: 'http://www.example.com/first-page')
    #
    # @param page_url [String] the page URL
    # @param page_title [String] the title of the page
    # @param referrer [String] the URL of the previous page
    def initialize(page_url: nil, page_title: nil, referrer: nil)
      @details = { 'url' => page_url,
                   'page' => page_title,
                   'refr' => referrer }
    end
  end
end
