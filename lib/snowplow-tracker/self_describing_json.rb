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
  # Creates the self-describing JSONs necessary for sending context or
  # self-describing events. These are a specific kind of [JSON
  # schema](http://json-schema.org/).
  #
  # A unique schema can be designed for each type of event or entity (for event
  # context) that you want to track. This allows you to track the specific
  # things that are important to you, in a way that is defined by you.
  #
  # A self-describing JSON has two keys, `schema` and `data`. The `schema` value
  # should point to a valid self-describing JSON schema. They are called
  # self-describing because the schema will specify the fields allowed in the
  # `data` value. After events have been collected by the event collector, they
  # are validated to ensure that the self-describing JSONs are correct. Mistakes
  # (e.g. extra fields, or incorrect types) will result in events being
  # processed as Bad Events.
  #
  # A SelfDescribingJson is initialized with `schema` and `data` as separate
  # arguments. These parameters are combined into a complete self-describing
  # JSON during the event creation, which is stringified and sent as part of the
  # event. By default, they will be sent base64-encoded. This can be changed on
  # {Tracker} initialization.
  #
  # The `data` argument must be a flat hash of key-value pairs. Either strings
  # or symbols are accepted as keys. The `schema` argument must be a correctly
  # formatted schema ID.
  #
  # When used to send event context data, stringified self-describing JSONs will
  # be sent in the raw event as `cx`, or `co` if not encoded. Whether encoded or
  # not, these strings will be converted back to JSON within the `contexts`
  # parameter of the processed event. All the event context is contained within
  # this one parameter, even if multiple context entities were sent.
  #
  # Self-describing JSONs in self-describing events are sent in a similar
  # manner. They are sent as `ue_px` in the raw event, or `ue_pr` if not
  # encoded. This is processed into the `unstruct_event` parameter of the
  # finished event.
  #
  # @example
  #   # This example schema describes an ad_click event.
  #   # It defines a single property for that event type, a "bannerId".
  #
  #   {
  #     "$schema": "http://json-schema.org/schema#",
  #     "self": {
  #         "vendor": "com.snowplowanalytics",
  #         "name": "ad_click",
  #         "format": "jsonschema",
  #         "version": "1-0-0"
  #     },
  #     "type": "object",
  #     "properties": {
  #         "bannerId": {
  #             "type": "string"
  #         }
  #     },
  #     "required": ["bannerId"],
  #     "additionalProperties": false
  #   }
  #
  #   # Creating the SelfDescribingJson
  #   schema_name = "iglu:com.snowplowanalytics/ad_click/jsonschema/1-0-0"
  #   event_data = { bannerId: "4acd518feb82" }
  #   SelfDescribingJson.new(schema_name, event_data)
  #
  #   # The self-describing JSON that will be sent (stringified) with the event
  #   {
  #     "schema": "iglu:com.snowplowanalytics/ad_click/jsonschema/1-0-0",
  #     "data": {
  #         "bannerId": "4acd518feb82"
  #     }
  #   }
  #
  # @api public
  # @see
  #   https://docs.snowplowanalytics.com/docs/understanding-tracking-design/understanding-schemas-and-validation/
  #   introduction to Snowplow schemas
  # @see
  #   https://docs.snowplowanalytics.com/docs/pipeline-components-and-applications/iglu/
  #   schema management using Iglu
  # @see
  #   https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/snowplow-tracker-protocol
  #   the Snowplow Tracker Protocol
  class SelfDescribingJson
    # @param schema [String] schema identifier
    # @param data [Hash] a flat hash that matches the description in the schema
    def initialize(schema, data)
      @schema = schema
      @data = data
    end

    # make the self-describing JSON out of the instance variables
    # @private
    def to_json
      {
        schema: @schema,
        data: @data
      }
    end
  end
end
