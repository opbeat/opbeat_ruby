require File::expand_path('../../spec_helper', __FILE__)
require 'opbeat'

describe Opbeat::Event do
  describe '.capture_message' do
    let(:message) { 'This is a message' }
    let(:hash) { Opbeat::Event.capture_message(message).to_hash }

    context 'for a Message' do
      it 'returns an event' do
        Opbeat::Event.capture_message(message).should be_a(Opbeat::Event)
      end

      it "sets the message to the value passed" do
        hash['message'].should == message
      end

      it 'has level ERROR' do
        hash['level'].should == 'error'
      end
    end
  end

  describe '.capture_exception' do
    let(:message) { 'This is a message' }
    let(:exception) { Exception.new(message) }
    let(:hash) { Opbeat::Event.capture_exception(exception).to_hash }

    context 'for an Exception' do
      it 'returns an event' do
        Opbeat::Event.capture_exception(exception).should be_a(Opbeat::Event)
      end

      it "sets the message to the exception's message and type" do
        hash['message'].should == "Exception: #{message}"
      end

      it 'has level ERROR' do
        hash['level'].should == 'error'
      end

      it 'uses the exception class name as the exception type' do
        hash['exception']['type'].should == 'Exception'
      end

      it 'uses the exception message as the exception value' do
        hash['exception']['value'].should == message
      end

      it 'does not belong to a module' do
        hash['exception']['module'].should == ''
      end
    end

    context 'for a nested exception type' do
      module Opbeat::Test
        class Exception < Exception; end
      end
      let(:exception) { Opbeat::Test::Exception.new(message) }

      it 'sends the module name as part of the exception info' do
        hash['exception']['module'].should == 'Opbeat::Test'
      end
    end

    context 'for a Opbeat::Error' do
      let(:exception) { Opbeat::Error.new }
      it 'does not create an event' do
        Opbeat::Event.capture_exception(exception).should be_nil
      end
    end

    context 'when the exception has a backtrace' do
      let(:exception) do
        e = Exception.new(message)
        e.stub(:backtrace).and_return([
          "/path/to/some/file:22:in `function_name'",
          "/some/other/path:1412:in `other_function'",
        ])
        e
      end

      it 'parses the backtrace' do
        hash['stacktrace']['frames'].length.should == 2
        hash['stacktrace']['frames'][0]['lineno'].should == 1412
        hash['stacktrace']['frames'][0]['function'].should == 'other_function'
        hash['stacktrace']['frames'][0]['filename'].should == '/some/other/path'

        hash['stacktrace']['frames'][1]['lineno'].should == 22
        hash['stacktrace']['frames'][1]['function'].should == 'function_name'
        hash['stacktrace']['frames'][1]['filename'].should == '/path/to/some/file'
      end

      it "sets the culprit" do
        hash['culprit'].should eq("/some/other/path in other_function")
      end

      context 'when a path in the stack trace is on the laod path' do
        before do
          $LOAD_PATH << '/some'
        end

        after do
          $LOAD_PATH.delete('/some')
        end

        it 'strips prefixes in the load path from frame filenames' do
          hash['stacktrace']['frames'][0]['filename'].should == 'other/path'
        end
      end
    end

    context 'when there is user context' do
      it 'sends the context and is_authenticated' do
        Opbeat::Event.set_context(:user => {:id => 99})
        hash = Opbeat::Event.capture_exception(exception).to_hash        
        hash['user'].should eq({:id => 99, :is_authenticated => true})
      end
    end

    context 'when there is extra context' do
      it 'sends the context and is_authenticated' do
        extra_context = {:jobid => 99}
        Opbeat::Event.set_context(:extra => extra_context)
        hash = Opbeat::Event.capture_exception(exception).to_hash        
        hash['extra'].should eq(extra_context)
      end
    end
  end
end
