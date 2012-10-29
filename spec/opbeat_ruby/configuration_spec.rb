require File::expand_path('../../spec_helper', __FILE__)
require 'opbeat_ruby'

describe OpbeatRuby::Configuration do
  before do
    # Make sure we reset the env in case something leaks in
    ENV.delete('OPBEAT_PROJECT_ID')
    ENV.delete('OPBEAT_ACCESS_TOKEN')
  end

  shared_examples 'a complete configuration' do
    it 'should have a server' do
      subject[:server].should == 'http://opbeat.localdomain/opbeat'
    end

    it 'should have an access token' do
      subject[:access_token].should == '67890'
    end

    it 'should have a project ID' do
      subject[:project_id].should == '42'
    end
  end

  # context 'being initialized with a server string' do
  #   before do
  #     subject.server = 'http://12345:67890@opbeat.localdomain/opbeat/42'
  #   end
  #   it_should_behave_like 'a complete configuration'
  # end

  # context 'being initialized with a DSN string' do
  #   before do
  #     subject.dsn = 'http://12345:67890@opbeat.localdomain/opbeat/42'
  #   end
  #   it_should_behave_like 'a complete configuration'
  # end

  context 'being initialized with options' do
    before do
      subject.server = 'http://opbeat.localdomain/opbeat'
      subject.access_token = '67890'
      subject.project_id = '42'
    end
    it_should_behave_like 'a complete configuration'
  end

  context 'being initialized with an environment variable' do
    subject do
      ENV['OPBEAT_PROJECT_ID'] = '42'
      ENV['OPBEAT_ACCESS_TOKEN'] = '67890'
      ENV['OPBEAT_SERVER'] = 'http://opbeat.localdomain/opbeat'
      OpbeatRuby::Configuration.new
    end
    it_should_behave_like 'a complete configuration'
  end
end
