require File::expand_path('../../spec_helper', __FILE__)
require 'opbeat'

describe Opbeat::Logger do
  context 'without a backend logger' do
    before do
      Opbeat.configuration.stub(:logger) { nil }
    end

    it 'should not error' do
      subject.fatal 'fatalmsg'
      subject.error 'errormsg'
      subject.warn 'warnmsg'
      subject.info 'infomsg'
      subject.debug 'debugmsg'
    end
  end

  context 'with a backend logger' do
    before do
      @logger = double('logger')
      Opbeat.configuration.stub(:logger) { @logger }
    end

    it 'should log fatal messages' do
      @logger.should_receive(:fatal).with('** [Opbeat] fatalmsg')
      subject.fatal 'fatalmsg'
    end

    it 'should log error messages' do
      @logger.should_receive(:error).with('** [Opbeat] errormsg')
      subject.error 'errormsg'
    end

    it 'should log warning messages' do
      @logger.should_receive(:warn).with('** [Opbeat] warnmsg')
      subject.warn 'warnmsg'
    end

    it 'should log info messages' do
      @logger.should_receive(:info).with('** [Opbeat] infomsg')
      subject.info 'infomsg'
    end

    it 'should log debug messages' do
      @logger.should_receive(:debug).with('** [Opbeat] debugmsg')
      subject.debug 'debugmsg'
    end

    it 'should log messages from blocks' do
      @logger.should_receive(:info).with('** [Opbeat] infoblock')
      subject.info { 'infoblock' }
    end
  end
end
