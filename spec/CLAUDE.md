# Snowplow Ruby Tracker - Testing Guide (spec/CLAUDE.md)

## Testing Overview
The Snowplow Ruby Tracker uses RSpec for testing with WebMock for HTTP stubbing and SimpleCov for code coverage. Tests are organized into unit tests (isolated component testing) and integration tests (end-to-end event tracking). The test suite ensures compatibility across Ruby 2.1 to 3.0+ versions.

## Test Environment Setup

### Required Test Dependencies
```ruby
# In Gemfile or gemspec
gem 'rspec', '~> 3.10'
gem 'webmock', '~> 3.14'
gem 'simplecov'           # Coverage reporting
gem 'simplecov-lcov'      # LCOV format output
```

### spec_helper.rb Configuration
The spec helper provides test infrastructure including HTTP stubbing, coverage reporting, and test helpers for inspecting tracker behavior.

## Testing Patterns & Conventions

### 1. HTTP Request Stubbing
All HTTP requests must be stubbed to avoid external dependencies:
```ruby
# ❌ Wrong: Real HTTP requests
emitter = SnowplowTracker::Emitter.new(endpoint: 'real-collector.com')

# ✅ Correct: Stubbed requests
stub_request(:any, /localhost/).to_return(status: 200)
emitter = SnowplowTracker::Emitter.new(endpoint: 'localhost')
```

### 2. Null Logger Pattern
Suppress log output in tests for cleaner output:
```ruby
# ✅ Correct: Use NULL_LOGGER constant
emitter = SnowplowTracker::Emitter.new(endpoint: 'localhost',
                                       options: { logger: NULL_LOGGER })
```

### 3. Accessing Private State
Tests expose private attributes for verification:
```ruby
module SnowplowTracker
  class Tracker
    attr_reader :settings, :encode_base64  # Expose for testing
  end
end
```

### 4. Emitter Test Helpers
spec_helper extends Emitter with test methods:
```ruby
# Access last GET request querystring
emitter.get_last_querystring

# Access last POST request body
emitter.get_last_body
```

## Unit Test Organization

### File Naming Convention
```
spec/unit/<class_name>_spec.rb
```

### Test Structure
```ruby
describe SnowplowTracker::ClassName do
  describe 'configuration' do
    # Initialization tests
  end
  
  describe '#method_name' do
    # Method-specific tests
  end
end
```

### Common Test Patterns

#### Configuration Testing
```ruby
describe 'configuration' do
  it 'should initialise with default settings' do
    obj = SnowplowTracker::Class.new
    expect(obj.setting).to eq(default_value)
  end
end
```

#### Event Tracking Testing
```ruby
it 'tracks event correctly' do
  tracker.track_page_view(page_url: 'example.com')
  expect(CGI.parse(emitter.get_last_querystring))
    .to include('e' => ['pv'], 'url' => ['example.com'])
end
```

#### Error Handling Testing
```ruby
it 'handles errors gracefully' do
  stub_request(:any, /nonexistent/).to_return(status: 404)
  expect { emitter.flush }.not_to raise_error
end
```

## Integration Test Patterns

### End-to-End Event Flow
```ruby
it 'sends complete event with all components' do
  emitter = create_emitter
  subject = create_subject
  tracker = SnowplowTracker::Tracker.new(emitters: emitter, subject: subject)
  
  tracker.track_page_view(page_url: 'test.com')
  
  verify_event_payload(emitter.get_last_querystring)
end
```

### Multi-Event Scenarios
```ruby
it 'handles transaction with items' do
  tracker.track_ecommerce_transaction(
    transaction: transaction_hash,
    items: items_array
  )
  
  # Verify transaction event + item events
  expect(emitter.buffer).to have(items_array.length + 1).events
end
```

## Testing Self-Describing Events

### Schema Validation
```ruby
# Test self-describing JSON structure
json = SnowplowTracker::SelfDescribingJson.new(
  'iglu:com.test/event/jsonschema/1-0-0',
  { key: 'value' }
)
expect(json.to_json).to include(schema: 'iglu:com.test/event/jsonschema/1-0-0')
```

### Context Testing
```ruby
# Verify context attachment
context = [SnowplowTracker::SelfDescribingJson.new(schema, data)]
tracker.track_page_view(page_url: 'test.com', context: context)

parsed = CGI.parse(emitter.get_last_querystring)
expect(parsed).to include('cx')  # Context present
```

## Async Emitter Testing

### Thread Safety
```ruby
it 'handles concurrent event submission' do
  async_emitter = SnowplowTracker::AsyncEmitter.new(endpoint: 'localhost')
  
  threads = 10.times.map do
    Thread.new { tracker.track_page_view(page_url: 'test.com') }
  end
  
  threads.each(&:join)
  async_emitter.flush
  
  expect(async_emitter.buffer).to be_empty
end
```

## Coverage Requirements

### SimpleCov Configuration
```ruby
SimpleCov.start do
  add_filter 'spec/'  # Exclude test files from coverage
end
```

### Coverage Metrics
- Aim for >90% code coverage
- Focus on branch coverage for conditionals
- Exclude generated code and test helpers

## Test Data Helpers

### Common Test Fixtures
```ruby
def valid_transaction
  {
    'order_id' => '12345',
    'total_value' => 99.99,
    'currency' => 'USD'
  }
end

def valid_item
  {
    'sku' => 'ABC123',
    'price' => 49.99,
    'quantity' => 2
  }
end
```

## Debugging Test Failures

### Inspecting HTTP Requests
```ruby
# Enable WebMock debugging
WebMock.after_request do |request, response|
  puts "Request: #{request.method} #{request.uri}"
  puts "Response: #{response.status}"
end
```

### Examining Event Payloads
```ruby
# Parse and inspect querystring
params = CGI.parse(emitter.get_last_querystring)
pp params  # Pretty print for debugging
```

## Common Test Pitfalls

### Timing Issues
```ruby
# ❌ Wrong: Race condition with async
async_emitter.input(event)
expect(async_emitter.buffer).to be_empty

# ✅ Correct: Explicit flush
async_emitter.input(event)
async_emitter.flush
expect(async_emitter.buffer).to be_empty
```

### State Leakage
```ruby
# ❌ Wrong: Shared state between tests
@@class_variable = []

# ✅ Correct: Instance variables reset per test
before(:each) { @instance_var = [] }
```

## Quick Reference

### RSpec Matchers
- `expect(value).to eq(expected)` - Exact equality
- `expect(hash).to include(key: value)` - Partial hash match
- `expect { code }.to raise_error(ErrorClass)` - Exception testing
- `expect(array).to have(n).items` - Collection size

### WebMock Helpers
- `stub_request(:get, url)` - Stub GET requests
- `stub_request(:post, url).with(body: hash)` - Stub POST with body
- `WebMock.disable_net_connect!` - Prevent real HTTP

### Test Execution
```bash
# Run all tests
rspec

# Run specific file
rspec spec/unit/tracker_spec.rb

# Run with pattern
rspec -e "tracks page views"

# Run with coverage
COVERAGE=true rspec
```

## Contributing to Test Suite

### Adding New Tests
1. Create test file in appropriate directory (unit/integration)
2. Follow existing naming conventions
3. Include necessary test helpers via spec_helper
4. Stub all external HTTP requests
5. Clean up any created test data

### Test Documentation
- Use descriptive test names that explain the behavior
- Group related tests with `describe` blocks
- Add comments for complex test scenarios
- Include examples of expected vs actual for clarity

### Performance Considerations
- Keep unit tests fast (<100ms per test)
- Mock expensive operations (HTTP, file I/O)
- Use `let` for lazy evaluation of test data
- Avoid unnecessary setup in `before(:all)`