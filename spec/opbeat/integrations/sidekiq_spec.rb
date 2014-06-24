require File::expand_path('../../../spec_helper', __FILE__)
require 'opbeat/integrations/sidekiq'
require 'sidekiq/testing'

class Bomber
  include Sidekiq::Worker

  def perform(ex)
    raise ex
  end
end

Sidekiq::Testing.inline!

describe Opbeat::Integrations::Sidekiq do
  it 'should call Opbeat::captureException on erronous jobs' do
    test_exception = Exception.new("Test exception")
    Opbeat.should_receive(:captureException).with(test_exception)

    Bomber.perform_async test_exception
  end
end
