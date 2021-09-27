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
  class Page
    include Contracts

    attr_reader :details

    Contract KeywordArgs[page_url: Maybe[String], page_title: Maybe[String], referrer: Maybe[String]] => Any
    def initialize(page_url: nil, page_title: nil, referrer: nil)
      @details = { 'url' => page_url,
                   'page' => page_title,
                   'refr' => referrer }
    end
  end
end
