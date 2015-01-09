require File::expand_path('../../spec_helper', __FILE__)
require 'opbeat'

describe Opbeat::Event do
  describe '.from_message' do
    let(:message) { 'This is a message' }
    let(:hash) { Opbeat::Event.from_message(message).to_hash }

    context 'for a Message' do
      it 'returns an event' do
        expect(Opbeat::Event.from_message(message)).to be_a(Opbeat::Event)
      end

      it "sets the message to the value passed" do
        expect(hash['message']).to eq(message)
      end

      it 'has level ERROR' do
        expect(hash['level']).to eq('error')
      end
    end
  end

  describe '.from_exception' do
    let(:message) { 'This is a message' }
    let(:exception) { Exception.new(message) }
    let(:hash) { Opbeat::Event.from_exception(exception).to_hash }

    context 'for an Exception' do
      it 'returns an event' do
        expect(Opbeat::Event.from_exception(exception)).to be_a(Opbeat::Event)
      end

      it "sets the message to the exception's message and type" do
        expect(hash['message']).to eq("Exception: #{message}")
      end

      it 'has level ERROR' do
        expect(hash['level']).to eq('error')
      end

      it 'uses the exception class name as the exception type' do
        expect(hash['exception']['type']).to eq('Exception')
      end

      it 'uses the exception message as the exception value' do
        expect(hash['exception']['value']).to eq(message)
      end

      it 'does not belong to a module' do
        expect(hash['exception']['module']).to eq('')
      end
    end

    context 'for a nested exception type' do
      module Opbeat::Test
        class Exception < Exception; end
      end
      let(:exception) { Opbeat::Test::Exception.new(message) }

      it 'sends the module name as part of the exception info' do
        expect(hash['exception']['module']).to eq('Opbeat::Test')
      end
    end

    context 'for a Opbeat::Error' do
      let(:exception) { Opbeat::Error.new }
      it 'does not create an event' do
        expect(Opbeat::Event.from_exception(exception)).to be_nil
      end
    end

    context 'when the exception has a backtrace' do
      let(:exception) do
        e = Exception.new(message)
        allow(e).to receive(:backtrace).and_return([
          "/path/to/some/file:22:in `function_name'",
          "/some/other/path:1412:in `other_function'",
        ])
        e
      end

      it 'parses the backtrace' do
        expect(hash['stacktrace']['frames'].length).to eq(2)
        expect(hash['stacktrace']['frames'][0]['lineno']).to eq(1412)
        expect(hash['stacktrace']['frames'][0]['function']).to eq('other_function')
        expect(hash['stacktrace']['frames'][0]['filename']).to eq('/some/other/path')

        expect(hash['stacktrace']['frames'][1]['lineno']).to eq(22)
        expect(hash['stacktrace']['frames'][1]['function']).to eq('function_name')
        expect(hash['stacktrace']['frames'][1]['filename']).to eq('/path/to/some/file')
      end

      it "sets the culprit" do
        expect(hash['culprit']).to eq("/some/other/path in other_function")
      end

      context 'when a path in the stack trace is on the laod path' do
        before do
          $LOAD_PATH << '/some'
        end

        after do
          $LOAD_PATH.delete('/some')
        end

        it 'strips prefixes in the load path from frame filenames' do
          expect(hash['stacktrace']['frames'][0]['filename']).to eq('other/path')
        end
      end
    end

    context 'when there is user context' do
      it 'sends the context and is_authenticated' do
        Opbeat::Event.set_context(:user => {:id => 99})
        hash = Opbeat::Event.from_exception(exception).to_hash
        expect(hash['user']).to eq({:id => 99, :is_authenticated => true})
      end
    end

    context 'when there is extra context' do
      it 'sends the context and is_authenticated' do
        extra_context = {:jobid => 99}
        Opbeat::Event.set_context(:extra => extra_context)
        hash = Opbeat::Event.from_exception(exception).to_hash
        expect(hash['extra']).to eq(extra_context)
      end
    end
  end
end
