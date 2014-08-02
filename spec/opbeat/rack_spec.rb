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


describe Opbeat::Rack do
  before do
    @exception = build_exception()
    @env = {
      'action_controller.instance' => TestController.new
    }
    Opbeat::HttpInterface.stub(:new) { Opbeat::Interface.new }
  end

  it 'should extract user info' do
    expected_user = TestController.new.current_user

    Opbeat::Event.capture_rack_exception(@exception, @env) do |event|
      user = event.to_hash['user']
      user[:id].should eq(expected_user.id)
      user[:email].should eq(expected_user.email)
      user[:username].should eq(expected_user.username)
      user[:is_authenticated].should eq(true)
    end
  end

  it 'should handle custom user method' do
    Opbeat.configuration.user_controller_method = :custom_user
    expected_user = TestController.new.custom_user

    Opbeat::Event.capture_rack_exception(@exception, @env) do |event|
      user = event.to_hash['user']
      user[:id].should eq(expected_user.id)
      user[:email].should eq(expected_user.email)
      user[:username].should eq(expected_user.username)
      user[:is_authenticated].should eq(true)
    end
  end

  it 'should handle missing user method' do
    Opbeat.configuration.user_controller_method = :missing_user_method
    expected_user = TestController.new.custom_user

    Opbeat::Event.capture_rack_exception(@exception, @env) do |event|
      event.user.should eq(nil)
    end
  end
end
