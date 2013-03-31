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
    vars["foo"].should eq("bar")
    vars["password"].should eq(Opbeat::Processor::SanitizeData::MASK)
    vars["the_secret"].should eq(Opbeat::Processor::SanitizeData::MASK)
    vars["a_password_here"].should eq(Opbeat::Processor::SanitizeData::MASK)
    vars["mypasswd"].should eq(Opbeat::Processor::SanitizeData::MASK)
  end

  it 'should filter credit card values' do
    data = {
      'ccnumba' => '4242424242424242'
    }

    result = @processor.process(data)
    result["ccnumba"].should eq(Opbeat::Processor::SanitizeData::MASK)
  end

end
