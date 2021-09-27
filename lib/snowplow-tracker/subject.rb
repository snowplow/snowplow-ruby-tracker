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
  class Subject
    include Contracts

    DEFAULT_PLATFORM = 'srv'
    SUPPORTED_PLATFORMS = %w[web app pc tv mob cnsl iot srv]

    attr_reader :details

    Contract None => Any
    def initialize
      @details = { 'p' => DEFAULT_PLATFORM }
    end

    # Specify the platform
    # Part of the public API
    #
    Contract String => Subject
    def set_platform(platform)
      raise "#{platform} is not a supported platform" unless SUPPORTED_PLATFORMS.include?(platform)

      @details['p'] = platform
      self
    end

    # Set the business-defined user ID for a user
    # Part of the public API
    #
    Contract String => Subject
    def set_user_id(user_id)
      @details['uid'] = user_id
      self
    end

    # Set fingerprint for the user
    # Part of the public API
    #
    Contract Num => Subject
    def set_fingerprint(fingerprint)
      @details['fp'] = fingerprint
      self
    end

    # Set the screen resolution for a device
    # Part of the public API
    #
    Contract KeywordArgs[width: Num, height: Num] => Subject
    def set_screen_resolution(width:, height:)
      @details['res'] = "#{width}x#{height}"
      self
    end

    # Set the dimensions of the current viewport
    # Part of the public API
    #
    Contract KeywordArgs[width: Num, height: Num] => Subject
    def set_viewport(width:, height:)
      @details['vp'] = "#{width}x#{height}"
      self
    end

    # Set the color depth of the device in bits per pixel
    # Part of the public API
    #
    Contract Num => Subject
    def set_color_depth(depth)
      @details['cd'] = depth
      self
    end

    # Set the timezone field
    # Part of the public API
    #
    Contract String => Subject
    def set_timezone(timezone)
      @details['tz'] = timezone
      self
    end

    # Set the language field
    # Part of the public API
    #
    Contract String => Subject
    def set_lang(lang)
      @details['lang'] = lang
      self
    end

    # Set the domain user ID
    # Part of the public API
    #
    Contract String => Subject
    def set_domain_user_id(duid)
      @details['duid'] = duid
      self
    end

    # Set the IP address field
    # Part of the public API
    #
    Contract String => Subject
    def set_ip_address(ip)
      @details['ip'] = ip
      self
    end

    # Set the user agent
    # Part of the public API
    #
    Contract String => Subject
    def set_useragent(useragent)
      @details['ua'] = useragent
      self
    end

    # Set the network user ID field
    # This overwrites the nuid field set by the collector
    # Part of the public API
    #
    Contract String => Subject
    def set_network_user_id(nuid)
      @details['tnuid'] = nuid
      self
    end
  end
end
