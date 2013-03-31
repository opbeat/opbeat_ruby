require File::expand_path('../../spec_helper', __FILE__)
require 'opbeat'

describe Opbeat do
  before do
    @send = double("send")
    @event = double("event")
    Opbeat.stub(:send) { @send }
    Opbeat::Event.stub(:capture_message) { @event }
    Opbeat::Event.stub(:capture_exception) { @event }
  end

  it 'captureMessage should send result of Event.capture_message' do
    message = "Test message"
    Opbeat::Event.should_receive(:capture_message).with(message)
    Opbeat.should_receive(:send).with(@event)

    Opbeat.captureMessage(message)
  end

  it 'captureException should send result of Event.capture_exception' do
    exception = build_exception()

    Opbeat::Event.should_receive(:capture_exception).with(exception)
    Opbeat.should_receive(:send).with(@event)

    Opbeat.captureException(exception)
  end
end
