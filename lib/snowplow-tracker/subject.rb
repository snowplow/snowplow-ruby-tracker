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
  # Subject objects store information about the user associated with the event,
  # such as their `user_id`, what type of device they used, or what size screen
  # that device had. Also, they store which platform the event occurred on -
  # e.g. server-side app, mobile, games console, etc.
  #
  # Subject parameters are saved into the tracked event as part of the 'atomic'
  # event properties, which have their own column in the eventual table of
  # events. For example, a Subject's `user_id` parameter will be sent as `uid`
  # in the raw event payload, ending up in the `user_id` column. These
  # parameters represent part of the [Snowplow Tracker
  # Protocol](https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/snowplow-tracker-protocol),
  # which defines a Snowplow event.
  #
  # Each {Tracker} is initialized with a Subject. This means that every event by
  # default has the platform (`p` parameter in the raw event) `srv`: server-side
  # app. Platform is the only preset Subject parameter, which can be overriden
  # using the {#set_platform} method. All other parameters must be set manually.
  # This can be done directly on the Subject, or, if it is associated with a
  # Tracker, via the Tracker, which has access to all the methods of its
  # Subject.
  #
  # Your server-side code may not have access to all these parameters, or they
  # might not be useful to you. All the Subject parameters are optional, except
  # `platform`.
  #
  # @example Subject methods can be called from their associated Tracker
  #   # Creating the components explicitly
  #   emitter = SnowplowTracker::Emitter.new(endpoint: 'localhost')
  #   subject = SnowplowTracker::Subject.new
  #   tracker = SnowplowTracker::Tracker.new(emitters: emitter, subject: subject)
  #
  #   # These lines are equivalent
  #   subject.set_user_id('12345')
  #   tracker.set_user_id('12345')
  #
  #   # This would also be equivalent
  #   emitter = SnowplowTracker::Emitter.new(endpoint: 'localhost')
  #   subject = SnowplowTracker::Subject.new
  #   subject.set_user_id('12345')
  #   tracker = SnowplowTracker::Tracker.new(emitters: emitter, subject: subject)
  #
  # @example Adding properties to the auto-generated Tracker-associated Subject
  #   # Creating the components
  #   emitter = SnowplowTracker::Emitter.new(endpoint: 'localhost')
  #   tracker = SnowplowTracker::Tracker.new(emitters: emitter)
  #
  #   # Set Subject parameters via the Tracker
  #   tracker.set_user_id('12345')
  #
  # Since many of the Subject parameters describe the user, different Subject
  # properties may often be desired for each event, if there are multiple users.
  # This can be achieved in one of two ways:
  #
  # 1. the properties of the Tracker-associated Subject can be overriden by the
  #    properties of an event-specific Subject. A Subject can be added to any
  #    Tracker `#track_x_event` method call, as one of the arguments. Remember to
  #    set the platform for the event Subject if you're not using `srv`.
  # 2. the Tracker-associated Subject can be swapped for another Subject, using
  #    the Tracker method {Tracker#set_subject}.
  #
  # @see Tracker#set_subject
  # @see
  #   https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/snowplow-tracker-protocol
  #   the Snowplow Tracker Protocol
  # @api public
  #
  # @note All the Subject instance methods return the Subject object, allowing
  #   method chaining, e.g.
  #   `Subject.new.set_timezone('Europe/London').set_user_id('12345')`
  class Subject
    include Contracts

    # @private
    DEFAULT_PLATFORM = 'srv'

    # @api public
    #
    # | `p` value | Platform |
    # | ---- | ---- |
    # | app | General App |
    # | cnsl | Games Console |
    # | iot | Internet of Things |
    # | mob | Mobile/Tablet |
    # | pc | Desktop/Laptop/Netbook |
    # | srv [DEFAULT] | Server-side App |
    # | tv | Connected TV |
    # | web | Web (including Mobile Web) |
    SUPPORTED_PLATFORMS = %w[app cnsl iot mob pc srv tv web]

    # Access the Subject parameters
    # @example
    #   Subject.new.set_user_id('12345').details
    #   => {"p"=>"srv", "uid"=>"12345"}
    # @api public
    attr_reader :details

    Contract None => Any
    # @api public
    def initialize
      @details = { 'p' => DEFAULT_PLATFORM }
    end

    Contract String => Subject
    # Set the platform to one of the supported platform values.
    # @note Value is sent in the event as `p` (raw event) or `platform` (processed event).
    # @see Subject::SUPPORTED_PLATFORMS
    # @param [String] platform a valid platform choice
    # @return self
    # @api public
    def set_platform(platform)
      raise "#{platform} is not a supported platform" unless SUPPORTED_PLATFORMS.include?(platform)

      @details['p'] = platform
      self
    end

    Contract String => Subject
    # Set the unique business-defined user ID for a user.
    # @note Value is sent in the event as `uid` (raw event) or `user_id` (processed event).
    # For example, an email address.
    # @example Example user IDs
    #   # an email address
    #   janet.bloggs@email.com
    #
    #   # a username
    #   janetabloggs2021
    #
    # @param [String] user_id a unique user ID
    # @return self
    # @api public
    def set_user_id(user_id)
      @details['uid'] = user_id
      self
    end

    Contract Num => Subject
    # Set a business-defined fingerprint for a user.
    # @note Value is sent in the event as `fp` (raw event) or `user_fingerprint` (processed event).
    # @param [Num] fingerprint a user fingerprint
    # @return self
    # @api public
    def set_fingerprint(fingerprint)
      @details['fp'] = fingerprint
      self
    end

    Contract KeywordArgs[width: Num, height: Num] => Subject
    # Set the device screen resolution.
    # @note Value is sent in the event as `res` (raw event) or `dvce_screenheight` and `dvce_screenwidth` (processed event).
    # @param [Num] width the screen width, in pixels (must be a positive integer)
    # @param [Num] height the screen height, in pixels (must be a positive integer)
    # @return self
    # @api public
    def set_screen_resolution(width:, height:)
      @details['res'] = "#{width}x#{height}"
      self
    end

    Contract KeywordArgs[width: Num, height: Num] => Subject
    # Set the dimensions of the current viewport.
    # @note Value is sent in the event as `vp` (raw event) or `br_viewwidth` and `br_viewheight` (processed event).
    # @param [Num] width the viewport width, in pixels (must be a positive integer)
    # @param [Num] height the viewport height, in pixels (must be a positive integer)
    # @return self
    # @api public
    def set_viewport(width:, height:)
      @details['vp'] = "#{width}x#{height}"
      self
    end

    Contract Num => Subject
    # Set the color depth of the device, in bits per pixel.
    # @note Value is sent in the event as `cd` (raw event) or `br_colordepth` (processed event).
    # @param [Num] depth the colour depth
    # @return self
    # @api public
    def set_color_depth(depth)
      @details['cd'] = depth
      self
    end

    Contract String => Subject
    # Set the timezone to that of the user's OS.
    # @note Value is sent in the event as `tz` (raw event) or `os_timezone` (processed event).
    # @example
    #   subject.set_timezone('Africa/Lagos')
    # @param [String] timezone the timezone
    # @return self
    # @api public
    def set_timezone(timezone)
      @details['tz'] = timezone
      self
    end

    Contract String => Subject
    # Set the language.
    # @note Value is sent in the event as `lang` (raw event) or `br_lang` (processed event).
    # @example Setting the language to Spanish
    #   subject.set_lang('es')
    # @param [String] lang the language being used on the device
    # @return self
    # @api public
    def set_lang(lang)
      @details['lang'] = lang
      self
    end

    Contract String => Subject
    # Set the domain user ID.
    # @note Value is sent in the event as `duid` (raw event) or `domain_userid` (processed event).
    # @see Subject#set_network_user_id
    # @see Subject#set_domain_session_id
    # @see Subject#set_domain_session_idx
    # @see https://github.com/simplybusiness/snowplow_ruby_duid/ snowplow_ruby_duid, a third party gem
    # @see https://github.com/snowplow-incubator/snowplow-ruby-tracker-examples
    #   Ruby tracker example Rails app
    # @example
    #   subject.set_domain_user_id('aeb1691c5a0ee5a6')
    # @param [String] duid the unique domain user ID
    # @return self
    # @api public
    #
    # The `domain_userid` is a client-side unique user ID, which is set by the
    # browser-based JavaScript tracker, and stored in a first party cookie
    # (cookie name: `_sp_id`). For stitching together client-side and
    # server-side events originating from the same user, the domain user ID can
    # be extracted from the cookie and set using this method. A third party gem,
    # [snowplow_ruby_duid](https://github.com/simplybusiness/snowplow_ruby_duid/),
    # has been created to help with this.
    #
    # @example Ruby on Rails: getting the domain_user_id from the cookie
    #   # Assuming the Snowplow JavaScript has also been incorporated
    #   # cookies are accessible only within a Controller
    #   def snowplow_domain_userid
    #     sp_cookie = cookies.find { |key, _value| key =~ /^_sp_id/ }
    #     sp_cookie.last.split(".").first if sp_cookie.present?
    #   end
    #
    def set_domain_user_id(duid)
      @details['duid'] = duid
      self
    end

    Contract String => Subject
    # Set the domain session ID.
    # @note Value is sent in the event as `sid` (raw event) or `domain_sessionid` (processed event).
    # @see Subject#set_network_user_id
    # @see Subject#set_domain_user_id
    # @see Subject#set_domain_session_idx
    # @example
    #   subject.set_domain_session_id('9c65e7f3-8e8e-470d-b243-910b5b300da0')
    # @param [String] sid the unique domain session ID
    # @return self
    # @api public
    #
    # The `domain_sessionid` is a client-side unique ID for a user's current
    # session. It is set by the browser-based JavaScript trackers, and stored in
    # a first party cookie (cookie name: `_sp_id`), along with other parameters
    # such as `domain_userid`. For stitching together client-side and
    # server-side events originating from the same user and session, the domain
    # session ID can be extracted from the cookie and set using this method.
    def set_domain_session_id(sid)
      @details['sid'] = sid
      self
    end

    Contract Num => Subject
    # Set the domain session index.
    # @note Value is sent in the event as `vid` (raw event) or `domain_sessionidx` (processed event).
    # @see Subject#set_network_user_id
    # @see Subject#set_domain_user_id
    # @see Subject#set_domain_session_id
    # @example
    #   subject.set_domain_session_idx(3)
    # @param [Num] vid the number of sessions
    # @return self
    # @api public
    #
    # The `domain_sessionidx` is a client-side property that records how many
    # visits (unique `domain_sessionid`s) a user (a unique `domain_userid`) has
    # made to the site. It is stored in the first party cookie set by the
    # JavaScript tracker, along with other parameters such as `domain_userid`.
    # For stitching together client-side and server-side events originating from
    # the same user and session, the domain session index can be extracted from
    # the cookie and set using this method.
    def set_domain_session_idx(vid)
      @details['vid'] = vid
      self
    end

    Contract String => Subject
    # Set the user's IP address.
    # @note Value is sent in the event as `ip` (raw event) or `user_ipaddress` (processed event).
    # @param [String] ip the IP address
    # @return self
    # @api public
    def set_ip_address(ip)
      @details['ip'] = ip
      self
    end

    Contract String => Subject
    # Set the browser user agent.
    # @note Value is sent in the event as `ua` (raw event) or `useragent` (processed event).
    # @example
    #   subject.set_useragent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:92.0) Gecko/20100101 Firefox/92.0')
    # @param [String] useragent the user agent string
    # @return self
    # @api public
    def set_useragent(useragent)
      @details['ua'] = useragent
      self
    end

    Contract String => Subject
    # Set the network user ID.
    # @note Value is sent in the event as `tnuid` (raw event) and `network_userid` (processed event).
    # @see Subject#set_domain_user_id
    #
    # The network user ID is, like the `domain_userid`, a cookie-based unique
    # user ID. It is stored in a third party cookie set by the event collector,
    # hence the name "network" as it is set at a network level. It is the
    # server-side user identifier. The raw event does not contain a `nuid`
    # value; the `network_userid` property is added when the event is processed.
    #
    # The default behaviour is for the collector to provide a new cookie/network
    # user ID for each event it receives. This method provides the ability to
    # override the collector cookie's value with your own generated ID.
    #
    # Domain user IDs set on the Subject in this way are sent as `tnuid` in the
    # raw event.
    #
    # @example
    #   subject.set_network_user_id('ecdff4d0-9175-40ac-a8bb-325c49733607')
    # @param [String] nuid the network user ID
    # @return self
    # @api public
    def set_network_user_id(nuid)
      @details['tnuid'] = nuid
      self
    end
  end
end
