require './lib/snowplow_tracker/payload.rb'

describe Snowplow::Payload, 'context' do

  before(:each) do
    @pb = Snowplow::Payload.new
  end

  it 'initializes with an empty context hash' do
    p @pb
    @pb.context.should eq({})
  end

  it 'adds single key-value pairs to the context' do
    @pb.add('key1', 'value1')
    @pb.add('key2', 'value2')
    @pb.context.should eq({'key1' => 'value1', 'key2' => 'value2'})
  end

  it 'adds a dictionary of key-value pairs to the context' do
    @pb.add_dict({
      'p' => 'mob',
      'tna' => 'cf',
      'aid' => 'cd767ae'
      })
    @pb.context.should eq({
      'p' => 'mob',
      'tna' => 'cf',
      'aid' => 'cd767ae'      
      })
  end

  it 'turns a JSON into a string and adds it to the context' do
    @pb.add_json({'a' => {'b' => [23, 54]}}, false, 'cx', 'co')
    @pb.context.should eq({
      'co' => "{\"a\":{\"b\":[23,54]}}" 
      })
  end

  it 'base64-encodes a JSON string' do
    @pb.add_json({'a' => {'b' => [23, 54]}}, true, 'cx', 'co')
    @pb.context.should eq({
      'cx' => "eyJhIjp7ImIiOlsyMyw1NF19fQ==\n"
      })
    
  end

end