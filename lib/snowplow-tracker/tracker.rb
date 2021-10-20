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


require 'securerandom'
require 'set'

module SnowplowTracker
  # Allows the tracking of events. The tracker accepts event properties to its
  # various `track_x_event` methods, and creates an appropriate event payload.
  # This payload is passed to one or more Emitters for sending to the event
  # collector.
  #
  # A Tracker is always associated with one {Subject}, and one or more
  # {Emitter}. The Subject object stores information about the user, and will be
  # generated automatically if one is not provided during initialization. It can
  # be swapped out for another Subject using {#set_subject}.
  #
  # Tracker objects can access the methods of their associated {Subject}, e.g.
  # {#set_user_id}.
  #
  # The Emitter, or an array of Emitters, must be given during initialization.
  # They will send the prepared events to the event collector. It's possible to
  # add further Emitters to an existing Tracker, using {#add_emitter}. However,
  # Emitters cannot be removed from Trackers.
  #
  # At initialization, two Tracker parameters can be set which will be added to
  # all events. The first is the Tracker namespace. This is especially useful to
  # distinguish between events from different Trackers, if more than one is
  # being used. The namespace value will be sent as the `tna` field in the raw
  # event, mapping to `name_tracker` in the processed event.
  #
  # The second user-set Tracker property is the app ID (`aid`; `app_id`). This
  # is the unique identifier for the site or application, and is particularly
  # useful for distinguishing between events when Snowplow tracking has been
  # implemented in multiple apps.
  #
  # The final initialization parameter is a setting for the base64-encoding of
  # any JSONs in the event payload. These will be the {SelfDescribingJson}s used
  # to provide context to events, or in the {#track_self_describing_event}
  # method. The default is for JSONs to be encoded. Once the Tracker has been
  # instantiated, it is not possible to change this setting.
  #
  # # Tracking events
  #
  # The Tracker `#track_x_event` methods all work similarly. An event payload is
  # created containing the relevant properties, which is passed to an {Emitter}
  # for sending. All payloads have a unique event ID (`event_id`) added to them
  # (a type-4 UUID created using the SecureRandom module). This is sent as the
  # `eid` field in the raw event.
  #
  # The Ruby tracker provides the ability to track multiple types of events
  # out-of-the-box. The `#track_x_event` methods range from single purpose
  # methods, such as {#track_page_view}, to the more complex but flexible
  # {#track_self_describing_event}, which can be used to track any kind of
  # event. We strongly recommend using {#track_self_describing_event} for your
  # tracking, as it allows you to design custom event types to match your
  # business requirements.
  #
  # This table gives the event type in the raw and processed events, defined in
  # the Snowplow Tracker Protocol. This is the `e` or `event` parameter. Note
  # that {#track_screen_view} calls {#track_self_describing_event} behind the
  # scenes, resulting in a `ue` event type.
  #
  # <br>
  #
  # | Tracker method | `e` (raw) | `event` (processed) |
  # | --- | --- | --- |
  # | {#track_self_describing_event} | `ue` | `unstruct` |
  # | {#track_struct_event} | `se` | `struct` |
  # | {#track_page_view} | `pv` | `page_view` |
  # | {#track_ecommerce_transaction} | `tr` and `ti` | `transaction` and `transaction_item` |
  # | {#track_screen_view} | `ue` | `unstruct` |
  #
  # <br>
  #
  # The name `ue`, "unstructured event", is partially depreciated. This event
  # type was originally created as a counterpart to "structured event", but the
  # name is misleading. An `unstruct` event requires a schema ruleset and
  # therefore can be considered more structured than a `struct` event. We prefer
  # the name "self-describing event", after the {SelfDescribingJson} schema.
  # Changing the event name in the Tracker Protocol would be a breaking change,
  # so for now the self-describing events are still sent as "unstruct".
  #
  # All the `#track_x_event` methods share common features and parameters. Every
  # type of event can have an optional context, {Subject}, and {Page} added. A
  # {Timestamp} can also be provided for all event types to override the default
  # event timestamp.
  #
  # [Event
  # context](https://docs.snowplowanalytics.com/docs/understanding-tracking-design/understanding-events-entities/)
  # can be provided as an array of {SelfDescribingJson}. Each element of the
  # array is called an entity. Contextual entities can be used to describe the
  # setting in which the event occurred. For example, a "user" entity could be
  # created and attached to all events from each user. For a search event,
  # entities could be attached for each of the search results. The Ruby tracker
  # does not automatically add any event context. This is in contrast to the
  # [Snowplow JavaScript Tracker](https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/javascript-trackers/),
  # which automatically attaches a "webpage" entity to every event that it tracks,
  # containing a unique ID for that loaded page.
  #
  # @see Subject
  # @see Emitter
  # @see
  #   https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/snowplow-tracker-protocol
  #   the Snowplow Tracker Protocol
  # @see
  #   https://docs.snowplowanalytics.com/docs/understanding-tracking-design/introduction-to-tracking-design/
  #   introduction to Snowplow tracking design
  # @api public
  class Tracker
    # @!group Public constants

    # SelfDescribingJson objects are sent encoded by default
    DEFAULT_ENCODE_BASE64 = true

    # @private
    BASE_SCHEMA_PATH = 'iglu:com.snowplowanalytics.snowplow'
    # @private
    SCHEMA_TAG = 'jsonschema'
    # @private
    CONTEXT_SCHEMA = "#{BASE_SCHEMA_PATH}/contexts/#{SCHEMA_TAG}/1-0-1"
    # @private
    UNSTRUCT_EVENT_SCHEMA = "#{BASE_SCHEMA_PATH}/unstruct_event/#{SCHEMA_TAG}/1-0-0"
    # @private
    SCREEN_VIEW_SCHEMA = "#{BASE_SCHEMA_PATH}/screen_view/#{SCHEMA_TAG}/1-0-0"

    # @!endgroup

    # Create a new Tracker. `emitters` is the only strictly required parameter.
    #
    # @param emitters [Emitter, Array<Emitter>] one or more Emitter objects
    # @param subject [Subject] a Subject object
    # @param namespace [String] a name for the Tracker
    # @param app_id [String] the app ID
    # @param encode_base64 [Bool] whether JSONs will be base64-encoded or not
    # @example Initializing a Tracker with all possible options
    #   Tracker.new(
    #               emitters: Emitter.new('collector.example.com'),
    #               subject: Subject.new,
    #               namespace: 'tracker_no_encode',
    #               app_id: 'rails_main',
    #               encode_base64: false
    #              )
    # @api public
    def initialize(emitters:, subject: nil, namespace: nil, app_id: nil, encode_base64: DEFAULT_ENCODE_BASE64)
      @emitters = Array(emitters)
      @subject = if subject.nil?
                   Subject.new
                 else
                   subject
                 end
      @settings = {
        'tna' => namespace,
        'tv'  => TRACKER_VERSION,
        'aid' => app_id
      }
      @encode_base64 = encode_base64
    end

    # @!method set_color_depth(depth)
    #   call {Subject#set_color_depth}
    # @!method set_domain_session_id(sid)
    #   call {Subject#set_domain_session_id}
    # @!method set_domain_session_idx(vid)
    #   call {Subject#set_domain_session_idx}
    # @!method set_domain_user_id(duid)
    #   call {Subject#set_domain_user_id}
    # @!method set_fingerprint(fingerprint)
    #   call {Subject#set_fingerprint}
    # @!method set_ip_address(ip)
    #   call {Subject#set_ip_address}
    # @!method set_lang(lang)
    #   call {Subject#set_lang}
    # @!method set_network_user_id(nuid)
    #   call {Subject#set_network_user_id}
    # @!method set_platform(platform)
    #   call {Subject#set_platform}
    # @!method set_screen_resolution(width:, height:)
    #   call {Subject#set_screen_resolution}
    # @!method set_timezone(timezone)
    #   call {Subject#set_timezone}
    # @!method set_user_id(user_id)
    #   call {Subject#set_user_id}
    # @!method set_useragent(useragent)
    #   call {Subject#set_useragent}
    # @!method set_viewport(width:, height:)
    #   call {Subject#set_viewport}
    Subject.instance_methods(false).each do |name|
      if RUBY_VERSION >= '3.0.0'
        define_method name, ->(*args, **kwargs) do
          @subject.method(name.to_sym).call(*args, **kwargs)

          self
        end
      else
        define_method name, ->(*args) do
          @subject.method(name.to_sym).call(*args)

          self
        end
      end
    end

    # Generates a type-4 UUID to identify this event
    # @private
    def event_id
      SecureRandom.uuid
    end

    # Builds a single self-describing JSON from an array of custom contexts
    # @private
    def build_context(context)
      SelfDescribingJson.new(
        CONTEXT_SCHEMA,
        context.map(&:to_json)
      ).to_json
    end

    # Sends the payload hash as a request to the Emitter(s)
    # @private
    def track(payload)
      @emitters.each { |emitter| emitter.input(payload.data) }

      nil
    end

    # Ensures that either a DeviceTimestamp or TrueTimestamp is associated with
    # every event.
    # @private
    def process_tstamp(tstamp)
      tstamp = Timestamp.create if tstamp.nil?
      tstamp = DeviceTimestamp.new(tstamp) if tstamp.is_a? Numeric
      tstamp
    end

    # Attaches the more generic fields to the event payload. This includes
    # context, Subject, and Page if they are present. The timestamp is added, as
    # well as all fields from `@settings`.
    #
    # Finally, the Tracker generates and attaches an event ID.
    # @private
    def finalise_payload(payload, context, tstamp, event_subject, page)
      payload.add_json(build_context(context), @encode_base64, 'cx', 'co') unless context.nil? || context.empty?
      payload.add_hash(page.details) unless page.nil?

      if event_subject.nil?
        payload.add_hash(@subject.details)
      else
        payload.add_hash(@subject.details.merge(event_subject.details))
      end

      payload.add(tstamp.type, tstamp.value)
      payload.add_hash(@settings)
      payload.add('eid', event_id)

      nil
    end

    # Track a visit to a page.
    #
    # @param page_url [String] the URL of the page
    # @param page_title [String] the page title
    # @param referrer [String] the URL of the referrer page
    # @param context [Array<SelfDescribingJson>] an array of SelfDescribingJson objects
    # @param tstamp [DeviceTimestamp, TrueTimestamp, Num] override the default DeviceTimestamp of the event
    # @param subject [Subject] event-specific Subject object
    # @param page [Page] override the page_url, page_title, or referrer
    #
    # @api public
    def track_page_view(page_url:, page_title: nil, referrer: nil,
                        context: nil, tstamp: nil, subject: nil, page: nil)
      tstamp = process_tstamp(tstamp)

      payload = Payload.new
      payload.add('e', 'pv')
      payload.add('url', page_url)
      payload.add('page', page_title)
      payload.add('refr', referrer)

      finalise_payload(payload, context, tstamp, subject, page)
      track(payload)

      self
    end

    # Track an eCommerce transaction, and all the items in it.
    #
    # This method is unique in sending multiple events: one `transaction` event,
    # and one `transaction_item` event for each item. If Subject or Page objects
    # are provided, their parameters will be merged into both `transaction` and
    # `transaction_item` events. The timestamp and event ID of the
    # `transaction_item` events will always be the same as the `transaction`.
    # Transaction items are also automatically populated with the `order_id` and
    # `currency` fields from the transaction.
    #
    # Event context is handled differently for `transaction` and
    # `transaction_item` events. A context array argument provided to this
    # method will be attached to the `transaction` event only. To attach a
    # context array to a transaction item, use the key "context" in the item
    # hash.
    #
    # The transaction and item hash arguments must contain the correct keys, as
    # shown in the tables below.
    #
    # | Transaction fields | Description | Required? | Type |
    # | --- | --- | --- | --- |
    # | order_id |  ID of the eCommerce transaction  | Yes  | String |
    # | total_value |  Total transaction value  | Yes  | Num |
    # | affiliation |  Transaction affiliation  | No  | String |
    # | tax_value |  Transaction tax value  | No  | Num |
    # | shipping |  Delivery cost charged  | No  | Num |
    # | city |  Delivery address city  | No  | String |
    # | state |  Delivery address state  | No  | String |
    # | country |  Delivery address country  | No  | String |
    # | currency |  Transaction currency  | No  | String |
    #
    # <br>
    #
    # | Item fields | Description | Required? | Type |
    # | --- | --- | --- | --- |
    # | sku | Item SKU  | Yes | String |
    # | price | Item price  | Yes | Num |
    # | quantity |  Item quantity | Yes | Integer |
    # | name |  Item name | No |  String |
    # | category |  Item category | No |  String |
    # | context | Item event context  | No |  Array[{SelfDescribingJson}] |
    #
    # @example Tracking a transaction containing two items
    #   SnowplowTracker::Tracker.new.track_ecommerce_transaction(
    #     transaction: {
    #       'order_id' => '12345',
    #       'total_value' => 49.99,
    #       'affiliation' => 'my_company',
    #       'tax_value' => 0,
    #       'shipping' => 0,
    #       'city' => 'Phoenix',
    #       'state' => 'Arizona',
    #       'country' => 'USA',
    #       'currency' => 'USD'
    #     },
    #     items: [
    #       {
    #         'sku' => 'pbz0026',
    #         'price' => 19.99,
    #         'quantity' => 1
    #       },
    #       {
    #         'sku' => 'pbz0038',
    #         'price' => 15,
    #         'quantity' => 2,
    #         'name' => 'crystals',
    #         'category' => 'magic'
    #       }
    #     ]
    #   )
    #
    # @param transaction [Hash] the correctly structured transaction hash
    # @param items [Array<Hash>] an array of correctly structured item hashes
    # @param context [Array<SelfDescribingJson>] an array of SelfDescribingJson objects
    # @param tstamp [DeviceTimestamp, TrueTimestamp, Num] override the default DeviceTimestamp of the event
    # @param subject [Subject] event-specific Subject object
    # @param page [Page] event-specific Page object
    #
    # @api public
    def track_ecommerce_transaction(transaction:, items:,
                                    context: nil, tstamp: nil,
                                    subject: nil, page: nil)
      tstamp = process_tstamp(tstamp)

      transform_keys(transaction)

      payload = Payload.new
      payload.add('e', 'tr')
      payload.add('tr_id', transaction['order_id'])
      payload.add('tr_tt', transaction['total_value'])
      payload.add('tr_af', transaction['affiliation'])
      payload.add('tr_tx', transaction['tax_value'])
      payload.add('tr_sh', transaction['shipping'])
      payload.add('tr_ci', transaction['city'])
      payload.add('tr_st', transaction['state'])
      payload.add('tr_co', transaction['country'])
      payload.add('tr_cu', transaction['currency'])

      finalise_payload(payload, context, tstamp, subject, page)

      track(payload)

      items.each do |item|
        transform_keys(item)
        item['tstamp'] = tstamp
        item['order_id'] = transaction['order_id']
        item['currency'] = transaction['currency']
        track_ecommerce_transaction_item(item, subject, page)
      end

      self
    end

    # Makes sure all hash keys are strings rather than symbols.
    # The Ruby core language added a method for this in Ruby 2.5.
    # @private
    def transform_keys(hash)
      hash.keys.each { |key| hash[key.to_s] = hash.delete key }
    end

    # Track a single item within an ecommerce transaction.
    # @private
    def track_ecommerce_transaction_item(details, subject, page)
      payload = Payload.new
      payload.add('e', 'ti')
      payload.add('ti_id', details['order_id'])
      payload.add('ti_sk', details['sku'])
      payload.add('ti_pr', details['price'])
      payload.add('ti_qu', details['quantity'])
      payload.add('ti_nm', details['name'])
      payload.add('ti_ca', details['category'])
      payload.add('ti_cu', details['currency'])

      finalise_payload(payload, details['context'], details['tstamp'], subject, page)
      track(payload)

      self
    end

    # Track a structured event. `category` and `action` are required.
    #
    # This event type can be used to track many types of user activity, as it is
    # somewhat customizable. This event type is provided particularly for
    # concordance with Google Analytics tracking, where events are structured by
    # "category", "action", "label", and "value".
    #
    # For fully customizable event tracking, we recommend you use
    # self-describing events.
    #
    # @see #track_self_describing_event
    #
    # @param category [String] the event category
    # @param action [String] the action performed
    # @param label [String] an event label
    # @param property [String] an event property
    # @param value [Num] a value for the event
    # @param context [Array<SelfDescribingJson>] an array of SelfDescribingJson objects
    # @param tstamp [DeviceTimestamp, TrueTimestamp, Num] override the default DeviceTimestamp of the event
    # @param subject [Subject] event-specific Subject object
    # @param page [Page] event-specific Page object
    #
    # @api public
    def track_struct_event(category:, action:, label: nil, property: nil,
                           value: nil, context: nil, tstamp: nil, subject: nil, page: nil)
      tstamp = process_tstamp(tstamp)

      payload = Payload.new
      payload.add('e', 'se')
      payload.add('se_ca', category)
      payload.add('se_ac', action)
      payload.add('se_la', label)
      payload.add('se_pr', property)
      payload.add('se_va', value)

      finalise_payload(payload, context, tstamp, subject, page)
      track(payload)

      self
    end

    # Track a screen view event. Note that while the `name` and `id` parameters
    # are both optional, you must provided at least one of them to create a
    # valid event.
    #
    # This method creates an `unstruct` event, by creating a
    # {SelfDescribingJson} and calling {#track_self_describing_event}. The
    # schema ID for this is
    # "iglu:com.snowplowanalytics.snowplow/screen_view/jsonschema/1-0-0", and
    # the data field will contain the name and/or ID.
    #
    # @see #track_page_view
    # @see #track_self_describing_event
    #
    # @param name [String] the screen name (human readable)
    # @param id [String] the unique screen ID
    # @param context [Array<SelfDescribingJson>] an array of SelfDescribingJson objects
    # @param tstamp [DeviceTimestamp, TrueTimestamp, Num] override the default DeviceTimestamp of the event
    # @param subject [Subject] event-specific Subject object
    # @param page [Page] event-specific Page object
    #
    # @api public
    def track_screen_view(name: nil, id: nil, context: nil, tstamp: nil, subject: nil, page: nil)
      screen_view_properties = {}
      screen_view_properties['name'] = name unless name.nil?
      screen_view_properties['id'] = id unless id.nil?

      event_json = SelfDescribingJson.new(SCREEN_VIEW_SCHEMA, screen_view_properties)
      track_unstruct_event(event_json: event_json, context: context,
                           tstamp: tstamp, subject: subject, page: page)

      self
    end

    # Track a self-describing event. These are custom events based on
    # {SelfDescribingJson}, i.e. a JSON schema and a defined set of properties.
    #
    # This is useful for tracking specific or proprietary event types, or events
    # with unpredicable or frequently changing properties.
    #
    # This method creates an `unstruct` event type. It is actually an alias for
    # {#track_unstruct_event}, which is depreciated due to its unhelpful name.
    #
    # @param event_json [SelfDescribingJson] a SelfDescribingJson object
    # @param context [Array<SelfDescribingJson>] an array of SelfDescribingJson objects
    # @param tstamp [DeviceTimestamp, TrueTimestamp, Num] override the default DeviceTimestamp of the event
    # @param subject [Subject] event-specific Subject object
    # @param page [Page] event-specific Page object
    #
    # @api public
    def track_self_describing_event(event_json:, context: nil, tstamp: nil, subject: nil, page: nil)
      track_unstruct_event(event_json: event_json, context: context,
                           tstamp: tstamp, subject: subject, page: page)
    end

    # @deprecated Use {#track_self_describing_event} instead.
    #
    # @api public
    def track_unstruct_event(event_json:, context: nil, tstamp: nil, subject: nil, page: nil)
      tstamp = process_tstamp(tstamp)

      payload = Payload.new
      payload.add('e', 'ue')

      envelope = SelfDescribingJson.new(UNSTRUCT_EVENT_SCHEMA, event_json.to_json)
      payload.add_json(envelope.to_json, @encode_base64, 'ue_px', 'ue_pr')

      finalise_payload(payload, context, tstamp, subject, page)
      track(payload)

      self
    end

    # Manually flush all events stored in all Tracker-associated Emitters. By
    # default, this happens synchronously. {Emitter}s can only send events
    # synchronously, while {AsyncEmitter}s can send either synchronously or
    # asynchronously.
    #
    # @param async [Bool] whether to flush asynchronously or not
    #
    # @api public
    def flush(async: false)
      @emitters.each do |emitter|
        emitter.flush(async)
      end

      self
    end

    # Replace the existing Tracker-associated Subject with the provided one. All
    # subsequent events will have the properties of the new Subject, unless they
    # are overriden by event-specific Subject parameters.
    #
    # @param subject [Subject] a Subject object
    #
    # @api public
    def set_subject(subject)
      @subject = subject
      self
    end

    # Add a new Emitter to the internal array of Tracker-associated Emitters.
    #
    # @param emitter [Emitter] an Emitter object
    #
    # @api public
    def add_emitter(emitter)
      @emitters.push(emitter)
      self
    end

    private :build_context,
            :track,
            :track_ecommerce_transaction_item
  end
end
