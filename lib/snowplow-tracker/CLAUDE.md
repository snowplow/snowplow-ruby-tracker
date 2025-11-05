# Snowplow Ruby Tracker - Core Library Implementation (lib/snowplow-tracker/CLAUDE.md)

## Library Module Overview
This directory contains the core implementation of the Snowplow Ruby Tracker. Each file represents a distinct component in the event tracking pipeline, following Ruby conventions for library design with clear separation of concerns and composable APIs.

## Component Implementation Patterns

### Module Namespace Convention
All classes must be defined within the `SnowplowTracker` module:
```ruby
# ❌ Wrong: Global namespace pollution
class Tracker
end

# ✅ Correct: Module encapsulation
module SnowplowTracker
  class Tracker
  end
end
```

### License Header Requirement
Every file must include the Apache 2.0 license header with proper attribution:
```ruby
# Copyright (c) 2013-2021 Snowplow Analytics Ltd. All rights reserved.
# [Full license text...]
# Author:: Snowplow Analytics Ltd
# Copyright:: Copyright (c) 2013-2021 Snowplow Analytics Ltd
# License:: Apache License Version 2.0
```

## Tracker Class Implementation

### Method Delegation Pattern
The Tracker delegates Subject methods using metaprogramming:
```ruby
# Dynamic method definition based on Ruby version
Subject.instance_methods(false).each do |name|
  if RUBY_VERSION >= '3.0.0'
    define_method name, ->(*args, **kwargs) do
      @subject.method(name.to_sym).call(*args, **kwargs)
      self  # Enable chaining
    end
  end
end
```

### Event ID Generation
Use SecureRandom for UUID v4 generation:
```ruby
def event_id
  SecureRandom.uuid  # Type-4 UUID
end
```

### Payload Finalization Pattern
```ruby
def finalise_payload(payload, context, tstamp, subject, page)
  # Order matters: context, page, subject, timestamp, settings, event_id
  payload.add_json(build_context(context), @encode_base64, 'cx', 'co')
  payload.add_hash(page.details) unless page.nil?
  payload.add_hash(@subject.details)
  # ...
end
```

## Emitter Implementation

### HTTP Method Configuration
```ruby
DEFAULT_CONFIG = {
  protocol: 'http',
  method: 'get'
}

# GET: buffer_size = 1 (single event)
# POST: buffer_size = 10 (batch events)
```

### Request Building Pattern
```ruby
def http_get(payload)
  uri = URI(@collector_uri + '?' + URI.encode_www_form(payload))
  Net::HTTP.get_response(uri)
end

def http_post(payload_array)
  req = Net::HTTP::Post.new(uri)
  req.body = { schema: POST_SCHEMA, data: payload_array }.to_json
  req['Content-Type'] = 'application/json'
end
```

### Buffer Management
```ruby
def input(payload)
  @buffer.push(payload)
  flush if @buffer.size >= @buffer_size
end
```

## Subject Class Patterns

### Default Platform Setting
```ruby
DEFAULT_PLATFORM = 'srv'  # Server-side application

SUPPORTED_PLATFORMS = %w[
  web mob pc srv app tv 
  cnsl iot
]
```

### Setter Method Pattern
All setters return self for chaining:
```ruby
def set_user_id(user_id)
  @details['uid'] = user_id
  self
end
```

### Parameter Mapping
Subject properties map to Tracker Protocol fields:
```ruby
# Ruby method -> Protocol field
set_user_id      -> 'uid'
set_platform     -> 'p'
set_lang         -> 'lang'
set_ip_address   -> 'ip'
```

## SelfDescribingJson Implementation

### Schema Format
```ruby
# Iglu schema identifier format
'iglu:{vendor}/{name}/{format}/{version}'
# Example: 'iglu:com.snowplowanalytics/ad_click/jsonschema/1-0-0'
```

### JSON Structure
```ruby
def to_json
  {
    schema: @schema,
    data: @data
  }
end
```

## Payload Assembly

### Field Addition Rules
```ruby
def add(name, value)
  # Only add non-empty, non-nil values
  @data[name] = value if (value != '') && !value.nil?
end
```

### JSON Encoding Pattern
```ruby
def add_json(json, encode_base64, encoded_key, plain_key)
  json_string = json.to_json.to_s
  if encode_base64
    @data[encoded_key] = Base64.strict_encode64(json_string)
  else
    @data[plain_key] = json_string
  end
end
```

## Timestamp Implementation

### Timestamp Types
```ruby
class DeviceTimestamp < Timestamp
  def initialize(value)
    super 'dtm', value  # Device-created timestamp
  end
end

class TrueTimestamp < Timestamp
  def initialize(value)
    super 'ttm', value  # True timestamp
  end
end
```

### Time Calculation
```ruby
def self.create
  (Time.now.to_f * 1000).to_i  # Milliseconds since epoch
end
```

## Page Context Pattern

### Property Storage
```ruby
def initialize(page_url: nil, page_title: nil, referrer: nil)
  @details = {
    'url' => page_url,
    'page' => page_title,
    'refr' => referrer
  }
end
```

## Error Handling Patterns

### Silent Failure for Optional Fields
```ruby
# Don't raise errors for nil optional fields
payload.add('optional_field', nil)  # Silently ignored
```

### Network Error Recovery
```ruby
begin
  response = http_get(payload)
  handle_success(response)
rescue StandardError => e
  logger.warn("Request failed: #{e.message}")
  handle_failure(payload)
end
```

## Version Management

### Version Constants
```ruby
module SnowplowTracker
  VERSION = '0.8.1-rc1'
  TRACKER_VERSION = "rb-#{VERSION}"  # Sent with events
end
```

## Schema Constants

### Base Schema Paths
```ruby
BASE_SCHEMA_PATH = 'iglu:com.snowplowanalytics.snowplow'
SCHEMA_TAG = 'jsonschema'
CONTEXT_SCHEMA = "#{BASE_SCHEMA_PATH}/contexts/#{SCHEMA_TAG}/1-0-1"
UNSTRUCT_EVENT_SCHEMA = "#{BASE_SCHEMA_PATH}/unstruct_event/#{SCHEMA_TAG}/1-0-0"
```

## Thread Safety Considerations

### AsyncEmitter Implementation
```ruby
# Use mutex for thread-safe buffer access
@lock = Mutex.new

def input(payload)
  @lock.synchronize do
    @buffer.push(payload)
  end
end
```

## API Design Principles

### 1. Fail Gracefully
Don't raise exceptions for tracking failures - log and continue.

### 2. Immutable Events
Once created, event payloads should not be modified.

### 3. Composable Components
Each component can be created and configured independently.

### 4. Method Chaining
All configuration methods return self for fluent interface.

### 5. Protocol Compliance
Strictly follow Snowplow Tracker Protocol field names and types.

## Common Implementation Pitfalls

### Ruby Version Compatibility
```ruby
# ❌ Wrong: Using Ruby 2.5+ features
hash.transform_keys(&:to_s)

# ✅ Correct: Compatible with Ruby 2.1+
hash.keys.each { |key| hash[key.to_s] = hash.delete key }
```

### Encoding Issues
```ruby
# ❌ Wrong: URL encoding issues
URI(@collector_uri + '?' + payload.to_query)

# ✅ Correct: Proper encoding
URI(@collector_uri + '?' + URI.encode_www_form(payload))
```

## Performance Optimizations

### Lazy Initialization
```ruby
def subject
  @subject ||= Subject.new
end
```

### Buffer Pre-allocation
```ruby
def initialize(buffer_size: 10)
  @buffer = []
  @buffer_size = buffer_size
end
```

## Quick Reference

### Event Type Mappings
- `pv` -> Page View
- `se` -> Structured Event
- `ue` -> Unstructured/Self-Describing Event
- `tr` -> Transaction
- `ti` -> Transaction Item

### Required Event Fields by Type
- **All Events**: `e`, `tv`, `eid`, timestamp
- **Page View**: `url`
- **Structured**: `se_ca`, `se_ac`
- **Self-Describing**: `ue_px` or `ue_pr`
- **Transaction**: `tr_id`, `tr_tt`

### Component Dependencies
```
Tracker -> Emitter (required)
        -> Subject (auto-created if not provided)
        -> Payload (created per event)
        -> SelfDescribingJson (for context/custom events)
```