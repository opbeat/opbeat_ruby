require File::expand_path('../../spec_helper', __FILE__)
require 'opbeat'

describe Opbeat do
  before do
    @send = double("send")
    @event = double("event")
    allow(Opbeat).to receive(:send) { @send }
    allow(Opbeat::Event).to receive(:from_message) { @event }
    allow(Opbeat::Event).to receive(:from_exception) { @event }
    allow(Opbeat::Event).to receive(:from_rack_exception) { @event }
  end

  it 'capture_message should send result of Event.from_message' do
    message = "Test message"
    expect(Opbeat::Event).to receive(:from_message).with(message, an_instance_of(Array), {})
    expect(Opbeat).to receive(:send).with(@event)

    Opbeat.capture_message(message)
  end

  it 'capture_message with options should send result of Event.from_message' do
    message = "Test message"
    options = {:extra => {:hello => "world"}}
    expect(Opbeat::Event).to receive(:from_message).with(message, an_instance_of(Array), options)
    expect(Opbeat).to receive(:send).with(@event)

    Opbeat.capture_message(message, options)
  end

  it 'capture_exception should send result of Event.from_exception' do
    exception = build_exception()

    expect(Opbeat::Event).to receive(:from_exception).with(exception, {})
    expect(Opbeat).to receive(:send).with(@event)

    Opbeat.capture_exception(exception)
  end

  it 'capture_rack_exception should send result of Event.from_exception built with env and default options' do
    exception = build_exception()
    rack_env = build_rack_env()

    expect(Opbeat::Event).to receive(:from_rack_exception).with(exception, rack_env, {})
    expect(Opbeat).to receive(:send).with(@event)

    Opbeat.capture_rack_exception(exception, rack_env)
  end

  it "capture_rack_exception should send result of Event.from_exception built with env and options" do
    exception = build_exception()
    rack_env = build_rack_env()

    expect(Opbeat::Event).to receive(:from_rack_exception).with(exception, rack_env, {:custom => :param})
    expect(Opbeat).to receive(:send).with(@event)

    Opbeat.capture_rack_exception(exception, rack_env, {:custom => :param})
  end

  context "async" do
    after do
      Opbeat.configuration.async = false
    end

    it 'capture_message should send result of Event.from_message' do
      async = lambda {}
      message = "Test message"

      expect(Opbeat::Event).to receive(:from_message).with(message, an_instance_of(Array), {})
      expect(Opbeat).to_not receive(:send)
      expect(async).to receive(:call).with(@event)

      Opbeat.configuration.async = async
      Opbeat.capture_message(message)
    end

    it 'capture_exception should send result of Event.from_exception' do
      async = lambda {}
      exception = build_exception()

      expect(Opbeat::Event).to receive(:from_exception).with(exception, {})
      expect(Opbeat).to_not receive(:send)
      expect(async).to receive(:call).with(@event)

      Opbeat.configuration.async = async
      Opbeat.capture_exception(exception)
    end
  end
end
