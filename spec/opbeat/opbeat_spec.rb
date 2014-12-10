require File::expand_path('../../spec_helper', __FILE__)
require 'opbeat'

describe Opbeat do
  before do
    @send = double("send")
    @event = double("event")
    allow(Opbeat).to receive(:send) { @send }
    allow(Opbeat::Event).to receive(:capture_message) { @event }
    allow(Opbeat::Event).to receive(:capture_exception) { @event }
  end

  it 'captureMessage should send result of Event.capture_message' do
    message = "Test message"
    expect(Opbeat::Event).to receive(:capture_message).with(message, {})
    expect(Opbeat).to receive(:send).with(@event)

    Opbeat.captureMessage(message)
  end

  it 'captureMessage with options should send result of Event.capture_message' do
    message = "Test message"
    options = {:extra => {:hello => "world"}}
    expect(Opbeat::Event).to receive(:capture_message).with(message, options)
    expect(Opbeat).to receive(:send).with(@event)

    Opbeat.captureMessage(message, options)
  end

  it 'captureException should send result of Event.capture_exception' do
    exception = build_exception()

    expect(Opbeat::Event).to receive(:capture_exception).with(exception, {})
    expect(Opbeat).to receive(:send).with(@event)

    Opbeat.captureException(exception)
  end

end
