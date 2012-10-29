require File::expand_path('../../spec_helper', __FILE__)
require 'opbeat_ruby'

describe OpbeatRuby do
  before do
    @send = double("send")
    @event = double("event")
    OpbeatRuby.stub(:send) { @send }
    OpbeatRuby::Event.stub(:capture_message) { @event }
    OpbeatRuby::Event.stub(:capture_exception) { @event }
  end

  it 'captureMessage should send result of Event.capture_message' do
    message = "Test message"
    OpbeatRuby::Event.should_receive(:capture_message).with(message)
    OpbeatRuby.should_receive(:send).with(@event)

    OpbeatRuby.captureMessage(message)
  end

  it 'captureException should send result of Event.capture_exception' do
    exception = build_exception()

    OpbeatRuby::Event.should_receive(:capture_exception).with(exception)
    OpbeatRuby.should_receive(:send).with(@event)

    OpbeatRuby.captureException(exception)
  end
end
