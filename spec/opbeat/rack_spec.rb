require File::expand_path('../../spec_helper', __FILE__)
require 'opbeat'

describe Opbeat::Rack do
  before do
    @send = double("send")
    @event = double("event")
    Opbeat.stub(:send) { @send }
    Opbeat::Event.stub(:capture_rack_exception) { @event }
  end

  it 'should capture exceptions' do
    exception = build_exception()
    env = {}
    
    Opbeat::Event.should_receive(:capture_rack_exception).with(exception, env)
    Opbeat.should_receive(:send).with(@event)

    app = lambda do |e|
      raise exception
    end

    stack = Opbeat::Rack.new(app)
    lambda {stack.call(env)}.should raise_error(exception)
  end

  it 'should capture rack.exception' do
    exception = build_exception()
    env = {}

    Opbeat::Event.should_receive(:capture_rack_exception).with(exception, env)
    Opbeat.should_receive(:send).with(@event)

    app = lambda do |e|
      e['rack.exception'] = exception
      [200, {}, ['okay']]
    end

    stack = Opbeat::Rack.new(app)

    stack.call(env)
  end
end
