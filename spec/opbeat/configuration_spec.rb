require File::expand_path('../../spec_helper', __FILE__)
require 'opbeat'

describe Opbeat::Configuration do
  before do
    # Make sure we reset the env in case something leaks in
    ENV.delete('OPBEAT_ORGANIZATION_ID')
    ENV.delete('OPBEAT_APP_ID')
    ENV.delete('OPBEAT_SECRET_TOKEN')
  end

  shared_examples 'a complete configuration' do
    it 'should have a server' do
      expect(subject[:server]).to eq('http://opbeat.localdomain/opbeat')
    end

    it 'should have an secret token' do
      expect(subject[:secret_token]).to eq('67890')
    end

    it 'should have an organization ID' do
      expect(subject[:organization_id]).to eq('42')
    end

    it 'should have an app ID' do
      expect(subject[:app_id]).to eq('43')
    end
  end

  context 'being initialized with options' do
    before do
      subject.server = 'http://opbeat.localdomain/opbeat'
      subject.secret_token = '67890'
      subject.organization_id = '42'
      subject.app_id = '43'
    end
    it_should_behave_like 'a complete configuration'
  end

  context 'being initialized with an environment variable' do
    subject do
      ENV['OPBEAT_ORGANIZATION_ID'] = '42'
      ENV['OPBEAT_APP_ID'] = '43'
      ENV['OPBEAT_SECRET_TOKEN'] = '67890'
      ENV['OPBEAT_SERVER'] = 'http://opbeat.localdomain/opbeat'
      Opbeat::Configuration.new
    end
    it_should_behave_like 'a complete configuration'
  end
end
