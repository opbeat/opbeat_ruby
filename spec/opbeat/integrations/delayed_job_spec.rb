require File.expand_path('../../../spec_helper', __FILE__)
require 'opbeat'
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


Delayed::Worker.backend = Delayed::Backend::Test::Job

describe Delayed::Plugins::Opbeat do
  class MyException < StandardError; end

  class Bomb
    def blow_up ex
      raise ex
    end
  end

  it 'should call Opbeat::capture_exception on erronous jobs' do
    test_exception = MyException.new("Test exception")
    expect(::Opbeat).to receive(:capture_exception).with(test_exception)

    Bomb.new.delay.blow_up test_exception

    expect(Delayed::Worker.new.work_off).to eq [0, 1]
  end
end
