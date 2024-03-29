# Copyright (c) 2013-2021 Snowplow Analytics Ltd. All rights reserved.
#
# This program is licensed to you under the Apache License Version 2.0,
# and you may not use this file except in compliance with the Apache License Version 2.0.
# You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the Apache License Version 2.0 is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.

# Author:: Snowplow Analytics Ltd
# Copyright:: Copyright (c) 2013-2021 Snowplow Analytics Ltd
# License:: Apache License Version 2.0


module SnowplowTracker
  # Creates timestamps for events. Timestamps are counted in milliseconds since
  # the Unix epoch (`(Time.now.to_f * 1000).to_i`).
  #
  # Snowplow events accrue timestamps as they are processed. When an event is
  # first generated by a {Tracker}, it has the raw event property `dtm`
  # ("device timestamp"; `dvce_created_tstamp` in the processed event)
  # or `ttm` ("true timestamp";`true_tstamp` in the processed event). These two
  # timestamps are set using the Timestamp subclasses {DeviceTimestamp} and
  # {TrueTimestamp}. The {Emitter} adds a `stm` ("sent timestamp";
  # `dvce_sent_tstamp`) property to the event just before sending it to the
  # collector. These timestamps are all processed into UTC time.
  #
  # Events can have either a device timestamp or a true timestamp, not both. By
  # default, the `#track_x_event` methods create a DeviceTimestamp. In some
  # circumstances, the device timestamp may be inaccurate. There are three
  # methods to override the default device timestamp value when the event is
  # created.
  #
  # 1. Provide your own calculated timestamp, as a Num (e.g. `1633596554978`),
  #    to the `#track_x_event` method. This will be converted into a
  #    DeviceTimestamp by the Tracker, and will still be recorded as `dtm` in
  #    the event.
  # 2. Manually create a DeviceTimestamp (e.g.
  #    `SnowplowTracker::DeviceTimestamp.new(1633596554978)`), and provide this to the
  #    `#track_x_event` method. This will still be recorded as `dtm` in the
  #    event.
  # 3. Provide a TrueTimestamp object to the `track_x_event` method (e.g.
  #    `SnowplowTracker::TrueTimestamp.new(1633596554978)`). This will result in a `ttm` field in
  #    the event.
  #
  # The timestamps that are added to the event once it has been emitted are not
  # the responsibility of this class. The collector receives the event and adds a
  # `collector_tstamp`. A later part of the pipeline adds the `etl_tstamp` when
  # the event enrichment has finished.
  #
  # When DeviceTimestamp is used, a `derived_tstamp` is also calculated and
  # added to the event. This timestamp attempts to take latency and possible
  # inaccuracy of the device clock into account. It is calculated by
  # `collector_tstamp - (dvce_sent_tstamp - dvce_created_tstamp)`. When
  # TrueTimestamp is used, the `derived_stamp` will be the same as
  # `true_tstamp`.
  #
  # @see
  #   https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/snowplow-tracker-protocol
  #   the Snowplow Tracker Protocol
  # @see
  #   https://discourse.snowplowanalytics.com/t/which-timestamp-is-the-best-to-see-when-an-event-occurred/538
  #   A Discourse forums post explaining timestamps
  # @api public
  class Timestamp
    # @private
    attr_reader :type

    # @private
    attr_reader :value

    # @private
    def initialize(type, value)
      @type = type
      @value = value
    end

    # Calculates time since the Unix epoch.
    # @private
    def self.create
      (Time.now.to_f * 1000).to_i
    end
  end

  # @see Timestamp
  # A very simple class that stores a timestamp, i.e. a numeric value
  # representing milliseconds since the Unix epoch, and which type of timestamp
  # it is, namely `ttm`. This raw event `ttm` field will be processed into
  # `true_tstamp` in the completed event.
  class TrueTimestamp < Timestamp
    # @param [Num] value timestamp in milliseconds since the Unix epoch
    # @example
    #   SnowplowTracker::TrueTimestamp.new(1633596346786)
    def initialize(value)
      super 'ttm', value
    end
  end

  # @see Timestamp
  # A very simple class that stores a timestamp, i.e. a numeric value
  # representing milliseconds since the Unix epoch, and which type of timestamp
  # it is, namely `dtm`. This raw event `dtm` field will be processed into
  # `dvce_created_tstamp` in the completed event.
  class DeviceTimestamp < Timestamp
    # @param [Num] value timestamp in milliseconds since the Unix epoch
    # @example
    #   SnowplowTracker::DeviceTimestamp.new(1633596346786)
    def initialize(value)
      super 'dtm', value
    end
  end
end
