# Snowplow Ruby Tracker - CLAUDE.md

## Project Overview
The Snowplow Ruby Tracker is a client library for sending analytics events to Snowplow collectors from Ruby applications. It provides a comprehensive event tracking API with support for structured events, self-describing events, page views, e-commerce transactions, and screen views. The library follows Ruby conventions and best practices while maintaining compatibility with Ruby 2.1 to 3.0+.

## Development Commands

### Building and Testing
```bash
# Install dependencies
bundle install

# Run all tests
rspec

# Run tests with Docker
docker build . -t ruby-tracker
docker run -v "$(pwd)":"/code" ruby-tracker

# Run specific test file
rspec spec/unit/tracker_spec.rb

# Run with coverage report
bundle exec rspec
```

### Code Quality
```bash
# Run RuboCop linter
bundle exec rubocop

# Generate YARD documentation
yard doc

# View documentation
yard server
```

### Gem Management
```bash
# Build gem
gem build snowplow-tracker.gemspec

# Install locally built gem
gem install snowplow-tracker-*.gem
```

## Architecture

### System Design
The tracker follows a clear separation of concerns with distinct components:
- **Tracker**: Main API surface, orchestrates event creation and dispatch
- **Emitter**: Handles HTTP communication with collectors (GET/POST)
- **Subject**: Stores user/device information attached to events
- **Payload**: Manages event data structure and encoding
- **SelfDescribingJson**: Implements Snowplow's schema-based event model
- **Page**: Encapsulates webpage context for events
- **Timestamp**: Handles device and true timestamp creation

### Event Flow
1. Client code calls `track_*` method on Tracker
2. Tracker creates Payload with event-specific fields
3. Subject/Page/Context data merged into Payload
4. Payload passed to Emitter(s) for transmission
5. Emitter buffers events and sends via HTTP(S)

## Core Architectural Principles

### 1. Immutable Event Pipeline
Events flow unidirectionally from Tracker through Emitter to collector. No backwards dependencies.

### 2. Composable Components
Each component (Subject, Page, Timestamp) can be created independently and composed at event time.

### 3. Multi-Emitter Support
Trackers can have multiple emitters for redundancy or different endpoints.

### 4. Schema-First Events
Self-describing events use Iglu schemas to define structure and validation.

### 5. Method Chaining API
All setter methods return self for fluent interface:
```ruby
tracker.set_user_id('123').track_page_view(page_url: 'example.com')
```

## Layer Organization & Responsibilities

### Public API Layer (`lib/snowplow-tracker/tracker.rb`)
- Event tracking methods (`track_page_view`, `track_struct_event`, etc.)
- Subject delegation via metaprogramming
- Event ID generation and context building

### Transport Layer (`lib/snowplow-tracker/emitters.rb`)
- HTTP/HTTPS communication
- Request buffering and batching
- Success/failure callbacks
- Automatic retry logic

### Data Model Layer
- `payload.rb`: Event data assembly and encoding
- `self_describing_json.rb`: Schema-based event structure
- `subject.rb`: User/device properties
- `page.rb`: Web page context
- `timestamp.rb`: Time handling

## Critical Import Patterns

### Module Structure
```ruby
# ❌ Wrong: Deep nesting without module
class Tracker
  # ...
end

# ✅ Correct: Proper module namespace
module SnowplowTracker
  class Tracker
    # ...
  end
end
```

### File Requirements
```ruby
# ❌ Wrong: Circular dependencies
require 'snowplow-tracker/tracker'
require 'snowplow-tracker/emitters'

# ✅ Correct: Single entry point
require 'snowplow-tracker'
```

## Essential Library Patterns

### Tracker Initialization
```ruby
# ❌ Wrong: Missing required emitter
tracker = SnowplowTracker::Tracker.new

# ✅ Correct: Emitter required
emitter = SnowplowTracker::Emitter.new(endpoint: 'collector.example.com')
tracker = SnowplowTracker::Tracker.new(emitters: emitter)
```

### Event Context Pattern
```ruby
# ❌ Wrong: Plain hash as context
tracker.track_page_view(page_url: 'example.com', context: { user: 'john' })

# ✅ Correct: SelfDescribingJson array
context = [SnowplowTracker::SelfDescribingJson.new('iglu:schema', { user: 'john' })]
tracker.track_page_view(page_url: 'example.com', context: context)
```

### Buffer Management
```ruby
# ❌ Wrong: GET with buffer > 1
emitter = SnowplowTracker::Emitter.new(endpoint: 'localhost', 
                                       options: { method: 'get', buffer_size: 10 })

# ✅ Correct: POST for batching
emitter = SnowplowTracker::Emitter.new(endpoint: 'localhost',
                                       options: { method: 'post', buffer_size: 10 })
```

## Model Organization Pattern

### Event Models
- **SelfDescribingJson**: Schema + data wrapper for custom events
- **Payload**: Internal event data structure (not public API)
- **Subject**: User/device properties container
- **Page**: Web page context container

### Timestamp Types
- **DeviceTimestamp**: Default, client-side time (`dtm` field)
- **TrueTimestamp**: Server-validated time (`ttm` field)

### Schema Naming Convention
```ruby
# Iglu schema format: iglu:{vendor}/{name}/{format}/{version}
'iglu:com.example/save_game/jsonschema/1-0-0'
```

## Common Pitfalls & Solutions

### Subject Scope Confusion
```ruby
# ❌ Wrong: Modifying global subject per-event
tracker.set_user_id('user1')
tracker.track_page_view(page_url: 'page1')  # user1
tracker.set_user_id('user2')
tracker.track_page_view(page_url: 'page2')  # user2 (affects all future events)

# ✅ Correct: Event-specific subject
subject1 = SnowplowTracker::Subject.new.set_user_id('user1')
subject2 = SnowplowTracker::Subject.new.set_user_id('user2')
tracker.track_page_view(page_url: 'page1', subject: subject1)
tracker.track_page_view(page_url: 'page2', subject: subject2)
```

### Synchronous Blocking
```ruby
# ❌ Wrong: Synchronous flush blocks execution
tracker.flush  # Blocks until all events sent

# ✅ Correct: Async flush for non-blocking
tracker.flush(async: true)
```

### Missing Required Fields
```ruby
# ❌ Wrong: Incomplete transaction
tracker.track_ecommerce_transaction(transaction: { total_value: 99.99 })

# ✅ Correct: All required fields
tracker.track_ecommerce_transaction(
  transaction: { 'order_id' => '123', 'total_value' => 99.99 },
  items: [{ 'sku' => 'ABC', 'price' => 99.99, 'quantity' => 1 }]
)
```

## File Structure Template

```
snowplow-ruby-tracker/
├── lib/
│   ├── snowplow-tracker.rb           # Main entry point
│   └── snowplow-tracker/
│       ├── version.rb                 # Version constant
│       ├── tracker.rb                 # Main Tracker class
│       ├── emitters.rb                # HTTP transport
│       ├── subject.rb                 # User properties
│       ├── payload.rb                 # Event data structure
│       ├── self_describing_json.rb    # Schema-based events
│       ├── page.rb                    # Page context
│       └── timestamp.rb               # Time handling
├── spec/
│   ├── spec_helper.rb                 # Test configuration
│   ├── unit/                          # Unit tests
│   │   ├── tracker_spec.rb
│   │   ├── emitters_spec.rb
│   │   ├── payload_spec.rb
│   │   └── timestamp_spec.rb
│   └── integration/                   # Integration tests
│       └── integration_spec.rb
├── Gemfile                            # Bundler dependencies
├── snowplow-tracker.gemspec           # Gem specification
└── .rubocop.yml                       # Linter configuration
```

## Testing Patterns

### WebMock Usage
```ruby
# Stub HTTP requests in specs
stub_request(:any, /localhost/)
  .to_return(status: 200, body: 'stubbed response')
```

### Spec Helper Monkey Patching
```ruby
# spec_helper.rb extends Emitter for testing
class Emitter
  def get_last_querystring(n = 1)
    @@querystrings[-n]
  end
end
```

### RSpec Configuration
```ruby
# Standard RSpec setup with WebMock
require 'spec_helper'
describe SnowplowTracker::Tracker do
  # Tests...
end
```

## Quick Reference

### Event Tracking Methods
- `track_page_view` - Web page visits
- `track_struct_event` - Structured events (category/action/label)
- `track_self_describing_event` - Custom schema events
- `track_screen_view` - Mobile/app screen views
- `track_ecommerce_transaction` - E-commerce purchases

### Required Parameters by Event Type
- **Page View**: `page_url`
- **Struct Event**: `category`, `action`
- **Self-Describing**: `event_json`
- **Screen View**: `name` or `id`
- **E-commerce**: `order_id`, `total_value`, items with `sku`, `price`, `quantity`

### Configuration Options
- **Emitter**: `endpoint`, `protocol`, `method`, `buffer_size`, `path`
- **Tracker**: `namespace`, `app_id`, `encode_base64`
- **Subject**: `user_id`, `platform`, `timezone`, `lang`, `ip_address`

## Contributing to CLAUDE.md

When adding or updating content in this document, please follow these guidelines:

### File Size Limit
- **CLAUDE.md must not exceed 40KB** (currently ~19KB)
- Check file size after updates: `wc -c CLAUDE.md`
- Remove outdated content if approaching the limit

### Code Examples
- Keep all code examples **4 lines or fewer**
- Focus on the essential pattern, not complete implementations
- Use `// ❌` and `// ✅` to clearly show wrong vs right approaches

### Content Organization
- Add new patterns to existing sections when possible
- Create new sections sparingly to maintain structure
- Update the architectural principles section for major changes
- Ensure examples follow current codebase conventions

### Quality Standards
- Test any new patterns in actual code before documenting
- Verify imports and syntax are correct for the codebase
- Keep language concise and actionable
- Focus on "what" and "how", minimize "why" explanations

### Multiple CLAUDE.md Files
- **Directory-specific CLAUDE.md files** can be created for specialized modules
- Follow the same structure and guidelines as this root CLAUDE.md
- Keep them focused on directory-specific patterns and conventions
- Maximum 20KB per directory-specific CLAUDE.md file

### Instructions for LLMs
When editing files in this repository, **always check for CLAUDE.md guidance**:

1. **Look for CLAUDE.md in the same directory** as the file being edited
2. **If not found, check parent directories** recursively up to project root
3. **Follow the patterns and conventions** described in the applicable CLAUDE.md
4. **Prioritize directory-specific guidance** over root-level guidance when conflicts exist