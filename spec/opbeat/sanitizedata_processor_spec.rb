require File::expand_path('../../spec_helper', __FILE__)
require 'opbeat/processors/sanitizedata'

describe Opbeat::Processor::SanitizeData do
  before do
    @client = double("client")
    @processor = Opbeat::Processor::SanitizeData.new(@client)
  end

  it 'should filter http data' do
    data = {
      'http' => {
        'data' => {
          'foo' => 'bar',
          'password' => 'hello',
          'the_secret' => 'hello',
          'a_password_here' => 'hello',
          'mypasswd' => 'hello',
        }
      }
    }

    result = @processor.process(data)

    vars = result["http"]["data"]
    expect(vars["foo"]).to eq("bar")
    expect(vars["password"]).to eq(Opbeat::Processor::SanitizeData::MASK)
    expect(vars["the_secret"]).to eq(Opbeat::Processor::SanitizeData::MASK)
    expect(vars["a_password_here"]).to eq(Opbeat::Processor::SanitizeData::MASK)
    expect(vars["mypasswd"]).to eq(Opbeat::Processor::SanitizeData::MASK)
  end

  it 'should filter credit card values' do
    data = {
      'ccnumba' => '4242424242424242'
    }

    result = @processor.process(data)
    expect(result["ccnumba"]).to eq(Opbeat::Processor::SanitizeData::MASK)
  end

end
