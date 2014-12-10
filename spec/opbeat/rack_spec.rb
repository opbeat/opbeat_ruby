require File::expand_path('../../spec_helper', __FILE__)

require 'opbeat'
require 'opbeat/interfaces'

class User
  attr_accessor :id, :email, :username
end


class TestController
  def current_user
    test_user = User.new
    test_user.id = 99
    test_user.email = "ron@opbeat.com"
    test_user.username = "roncohen"

    return test_user
  end

  def custom_user
    test_user = User.new
    test_user.id = 999
    test_user.email = "custom@opbeat.com"
    test_user.username = "custom"

    return test_user
  end
end



describe Opbeat::Rack do
  before do
    @send = double("send")
    @event = double("event")
    allow(Opbeat).to receive(:send) { @send }
    allow(Opbeat::Event).to receive(:capture_rack_exception) { @event }
  end

  it 'should capture exceptions' do
    exception = build_exception()
    env = {}
    
    expect(Opbeat::Event).to receive(:capture_rack_exception).with(exception, env)
    expect(Opbeat).to receive(:send).with(@event)

    app = lambda do |e|
      raise exception
    end

    stack = Opbeat::Rack.new(app)
    expect(lambda {stack.call(env)}).to raise_error(exception)
  end

  it 'should capture rack.exception' do
    exception = build_exception()
    env = {}

    expect(Opbeat::Event).to receive(:capture_rack_exception).with(exception, env)
    expect(Opbeat).to receive(:send).with(@event)

    app = lambda do |e|
      e['rack.exception'] = exception
      [200, {}, ['okay']]
    end

    stack = Opbeat::Rack.new(app)

    stack.call(env)
  end
end


describe Opbeat::Rack do
  before do
    @exception = build_exception()
    @env = {
      'action_controller.instance' => TestController.new
    }
    allow(Opbeat::HttpInterface).to receive(:new) { Opbeat::Interface.new }
  end

  it 'should extract user info' do
    expected_user = TestController.new.current_user

    Opbeat::Event.capture_rack_exception(@exception, @env) do |event|
      user = event.to_hash['user']
      expect(user[:id]).to eq(expected_user.id)
      expect(user[:email]).to eq(expected_user.email)
      expect(user[:username]).to eq(expected_user.username)
      expect(user[:is_authenticated]).to eq(true)
    end
  end

  it 'should handle custom user method' do
    Opbeat.configuration.user_controller_method = :custom_user
    expected_user = TestController.new.custom_user

    Opbeat::Event.capture_rack_exception(@exception, @env) do |event|
      user = event.to_hash['user']
      expect(user[:id]).to eq(expected_user.id)
      expect(user[:email]).to eq(expected_user.email)
      expect(user[:username]).to eq(expected_user.username)
      expect(user[:is_authenticated]).to eq(true)
    end
  end

  it 'should handle missing user method' do
    Opbeat.configuration.user_controller_method = :missing_user_method
    expected_user = TestController.new.custom_user

    Opbeat::Event.capture_rack_exception(@exception, @env) do |event|
      expect(event.user).to eq(nil)
    end
  end
end
