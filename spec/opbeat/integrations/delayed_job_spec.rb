require File::expand_path('../../../spec_helper', __FILE__)
require 'time'
require 'delayed_job'
require 'opbeat/integrations/delayed_job'

# turtles, all the way down
# trying too hard
require 'active_support/core_ext/time/calculations.rb'
load File.join(
  Gem::Specification.find_by_name("delayed_job").gem_dir,
  "spec", "delayed", "backend", "test.rb"
)


class Bomb
  def blow_up ex
    raise ex
  end
end


Delayed::Worker.backend = Delayed::Backend::Test::Job

describe Delayed::Plugins::Opbeat do
  it 'should call Opbeat::captureException on erronous jobs' do
    test_exception = Exception.new("Test exception")
    Opbeat.should_receive(:captureException).with(test_exception)

    # Queue
    bomb = Bomb.new
    bomb.delay.blow_up test_exception

    expect {
      Delayed::Worker.new.work_off.should == [0, 1]
    }.to raise_error(Exception)
  end
end

