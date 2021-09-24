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
require 'securerandom'
require 'set'

module SnowplowTracker
  class Tracker
    include Contracts

    # Contract types
    EMITTER_INPUT = Or[->(x) { x.is_a? Emitter }, ArrayOf[->(x) { x.is_a? Emitter }]]

    REQUIRED_TRANSACTION_KEYS =   Set.new(%w[order_id total_value])
    RECOGNISED_TRANSACTION_KEYS = Set.new(%w[
                                            order_id total_value affiliation tax_value
                                            shipping city state country currency
                                          ])

    TRANSACTION = ->(x) {
      return false unless x.class == Hash
      transaction_keys = Set.new(x.keys.map(&:to_s))
      REQUIRED_TRANSACTION_KEYS.subset?(transaction_keys) &&
        transaction_keys.subset?(RECOGNISED_TRANSACTION_KEYS)
    }

    REQUIRED_ITEM_KEYS =   Set.new(%w[sku price quantity])
    RECOGNISED_ITEM_KEYS = Set.new(%w[sku price quantity name category context])

    ITEM = ->(x) {
      return false unless x.class == Hash
      item_keys = Set.new(x.keys.map(&:to_s))
      REQUIRED_ITEM_KEYS.subset?(item_keys) &&
        item_keys.subset?(RECOGNISED_ITEM_KEYS)
    }

    REQUIRED_AUGMENTED_ITEM_KEYS =   Set.new(%w[sku price quantity tstamp order_id])
    RECOGNISED_AUGMENTED_ITEM_KEYS = Set.new(%w[sku price quantity name category context tstamp order_id currency])

    AUGMENTED_ITEM = ->(x) {
      return false unless x.class == Hash
      augmented_item_keys = Set.new(x.keys)
      REQUIRED_AUGMENTED_ITEM_KEYS.subset?(augmented_item_keys) &&
        augmented_item_keys.subset?(RECOGNISED_AUGMENTED_ITEM_KEYS)
    }

    CONTEXTS_INPUT = ArrayOf[SelfDescribingJson]

    # Other constants
    DEFAULT_ENCODE_BASE64 = true
    BASE_SCHEMA_PATH = 'iglu:com.snowplowanalytics.snowplow'
    SCHEMA_TAG = 'jsonschema'
    CONTEXT_SCHEMA = "#{BASE_SCHEMA_PATH}/contexts/#{SCHEMA_TAG}/1-0-1"
    UNSTRUCT_EVENT_SCHEMA = "#{BASE_SCHEMA_PATH}/unstruct_event/#{SCHEMA_TAG}/1-0-0"

    Contract KeywordArgs[emitters: EMITTER_INPUT, subject: Maybe[Subject], namespace: Maybe[String],
                         app_id: Maybe[String], encode_base64: Optional[Bool]] => Any
    def initialize(emitters:, subject: nil, namespace: nil, app_id: nil, encode_base64: DEFAULT_ENCODE_BASE64)
      @emitters = Array(emitters)
      @subject = if subject.nil?
                   Subject.new
                 else
                   subject
                 end
      @standard_nv_pairs = {
        'tna' => namespace,
        'tv'  => TRACKER_VERSION,
        'aid' => app_id
      }
      @config = {
        'encode_base64' => encode_base64
      }
    end

    # Call subject methods from tracker instance
    #
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
    #
    Contract nil => String
    def event_id
      SecureRandom.uuid
    end

    # Builds a self-describing JSON from an array of custom contexts
    #
    Contract CONTEXTS_INPUT => Hash
    def build_context(context)
      SelfDescribingJson.new(
        CONTEXT_SCHEMA,
        context.map(&:to_json)
      ).to_json
    end

    # Tracking methods

    # Attaches all the fields in @standard_nv_pairs to the request
    # Only attaches the context vendor if the event has a custom context
    #
    Contract Payload => nil
    def track(payload)
      payload.add_hash(@subject.standard_nv_pairs)
      payload.add_hash(@standard_nv_pairs)
      payload.add('eid', event_id)
      @emitters.each { |emitter| emitter.input(payload.context) }

      nil
    end

    # Log a visit to this page. Default is to insert a device timestamp
    # Part of the public API
    #
    Contract KeywordArgs[page_url: String, page_title: Maybe[String], referrer: Maybe[String],
                         context: Maybe[CONTEXTS_INPUT], tstamp: Or[Timestamp, Num, nil]] => Tracker
    def track_page_view(page_url:, page_title: nil, referrer: nil, context: nil, tstamp: nil)
      tstamp = Timestamp.create if tstamp.nil?
      tstamp = DeviceTimestamp.new(tstamp) if tstamp.is_a? Numeric

      payload = Payload.new
      payload.add('e', 'pv')
      payload.add('url', page_url)
      payload.add('page', page_title)
      payload.add('refr', referrer)

      payload.add_json(build_context(context), @config['encode_base64'], 'cx', 'co') unless context.nil?

      payload.add(tstamp.type, tstamp.value)

      track(payload)

      self
    end

    # Track an ecommerce transaction and all the items in it
    # By default, set the timestamp as the device timestamp
    # Part of the public API
    #
    Contract KeywordArgs[transaction: TRANSACTION, items: ArrayOf[ITEM],
                         context: Maybe[CONTEXTS_INPUT], tstamp: Or[Timestamp, Num, nil]] => Tracker
    def track_ecommerce_transaction(transaction:, items:,
                                    context: nil, tstamp: nil)
      tstamp = Timestamp.create if tstamp.nil?
      tstamp = DeviceTimestamp.new(tstamp) if tstamp.is_a? Numeric

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
      payload.add_json(build_context(context), @config['encode_base64'], 'cx', 'co') unless context.nil?

      payload.add(tstamp.type, tstamp.value)

      track(payload)

      items.each do |item|
        transform_keys(item)
        item['tstamp'] = tstamp
        item['order_id'] = transaction['order_id']
        item['currency'] = transaction['currency']
        track_ecommerce_transaction_item(item)
      end

      self
    end

    # The Ruby core language added a method for this in Ruby 2.5
    # Makes sure all hash keys are strings rather than symbols
    #
    def transform_keys(hash)
      hash.keys.each { |key| hash[key.to_s] = hash.delete key }
    end

    # Track a single item within an ecommerce transaction
    # Not part of the public API
    #
    Contract AUGMENTED_ITEM => self
    def track_ecommerce_transaction_item(argmap)
      payload = Payload.new
      payload.add('e', 'ti')
      payload.add('ti_id', argmap['order_id'])
      payload.add('ti_sk', argmap['sku'])
      payload.add('ti_pr', argmap['price'])
      payload.add('ti_qu', argmap['quantity'])
      payload.add('ti_nm', argmap['name'])
      payload.add('ti_ca', argmap['category'])
      payload.add('ti_cu', argmap['currency'])
      unless argmap['context'].nil?
        payload.add_json(
          build_context(argmap['context']),
          @config['encode_base64'],
          'cx',
          'co'
        )
      end
      payload.add(argmap['tstamp'].type, argmap['tstamp'].value)
      track(payload)

      self
    end

    # Track a structured event
    # By default, set the timestamp as the device timestamp
    # Part of the public API
    #
    Contract KeywordArgs[category: String, action: String, label: Maybe[String], property: Maybe[String],
                         value: Maybe[Num], context: Maybe[CONTEXTS_INPUT],
                         tstamp: Or[Timestamp, Num, nil]] => Tracker
    def track_struct_event(category:, action:, label: nil, property: nil, value: nil, context: nil, tstamp: nil)
      tstamp = Timestamp.create if tstamp.nil?
      tstamp = DeviceTimestamp.new(tstamp) if tstamp.is_a? Numeric

      payload = Payload.new
      payload.add('e', 'se')
      payload.add('se_ca', category)
      payload.add('se_ac', action)
      payload.add('se_la', label)
      payload.add('se_pr', property)
      payload.add('se_va', value)
      payload.add_json(build_context(context), @config['encode_base64'], 'cx', 'co') unless context.nil?

      payload.add(tstamp.type, tstamp.value)
      track(payload)

      self
    end

    # Track a screen view event
    # Part of the public API
    #
    Contract KeywordArgs[name: Maybe[String], id: Maybe[String], context: Maybe[CONTEXTS_INPUT],
                         tstamp: Or[Timestamp, Num, nil]] => Tracker
    def track_screen_view(name: nil, id: nil, context: nil, tstamp: nil)
      screen_view_properties = {}
      screen_view_properties['name'] = name unless name.nil?
      screen_view_properties['id'] = id unless id.nil?
      screen_view_schema = "#{BASE_SCHEMA_PATH}/screen_view/#{SCHEMA_TAG}/1-0-0"

      event_json = SelfDescribingJson.new(screen_view_schema, screen_view_properties)

      track_unstruct_event(event_json: event_json, context: context, tstamp: tstamp)

      self
    end

    # Better name for track unstruct event
    # By default, sets the timestamp to the device timestamp
    # Part of the public API
    #
    Contract KeywordArgs[event_json: SelfDescribingJson, context: Maybe[CONTEXTS_INPUT],
                         tstamp: Or[Timestamp, Num, nil]] => Tracker
    def track_self_describing_event(event_json:, context: nil, tstamp: nil)
      track_unstruct_event(event_json: event_json, context: context, tstamp: tstamp)
    end

    # Track an unstructured event
    # By default, sets the timestamp to the device timestamp
    #
    Contract KeywordArgs[event_json: SelfDescribingJson, context: Maybe[CONTEXTS_INPUT],
                         tstamp: Or[Timestamp, Num, nil]] => Tracker
    def track_unstruct_event(event_json:, context: nil, tstamp: nil)
      tstamp = Timestamp.create if tstamp.nil?
      tstamp = DeviceTimestamp.new(tstamp) if tstamp.is_a? Numeric

      payload = Payload.new
      payload.add('e', 'ue')

      envelope = SelfDescribingJson.new(UNSTRUCT_EVENT_SCHEMA, event_json.to_json)

      payload.add_json(envelope.to_json, @config['encode_base64'], 'ue_px', 'ue_pr')

      payload.add_json(build_context(context), @config['encode_base64'], 'cx', 'co') unless context.nil?

      payload.add(tstamp.type, tstamp.value)

      track(payload)

      self
    end

    # Flush all events stored in all emitters
    # Part of the public API
    #
    Contract KeywordArgs[async: Optional[Bool]] => Tracker
    def flush(async: false)
      @emitters.each do |emitter|
        emitter.flush(async)
      end

      self
    end

    # Set the subject of the events fired by the tracker
    # Part of the public API
    #
    Contract Subject => Tracker
    def set_subject(subject)
      @subject = subject
      self
    end

    # Add a new emitter
    # Part of the public API
    #
    Contract Emitter => Tracker
    def add_emitter(emitter)
      @emitters.push(emitter)
      self
    end

    private :build_context,
            :track,
            :track_ecommerce_transaction_item
  end
end
