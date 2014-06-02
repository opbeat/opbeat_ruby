require File::expand_path('../../spec_helper', __FILE__)
require 'opbeat'

describe Opbeat::Client do
  before do

    @configuration = Opbeat::Configuration.new
    @configuration.environments = ["test"]
    @configuration.current_environment = :test
    @client = Opbeat::Client.new(@configuration)
    @client.stub(:send)
    # @client.stub(:send) { "bleh" }

  #   @event = double("event")
  #   Opbeat.stub(:send) { @send }
      
  #   Opbeat::Event.stub(:capture_exception) { @event }
  end

  it 'send_release should send' do
    message = "Test message"
    @client.should_receive(:send).with("/releases/", message)
    @client.send_release(message)
  end

  it 'send_message should send' do
    event = Opbeat::Event.new :message => "my message"
    @client.should_receive(:send).with("/errors/", event)
    @client.send_event(event)
  end


  # it 'send_release should send' do
  #   exception = build_exception()

  #   Opbeat::Event.should_receive(:capture_exception).with(exception)
  #   Opbeat.should_receive(:send).with(@event)

  #   Opbeat.captureException(exception)
  # end
end
