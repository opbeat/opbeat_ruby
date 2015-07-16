require 'opbeat/version'
require 'opbeat/configuration'
require 'opbeat/logger'
require 'opbeat/client'
require 'opbeat/event'
require 'opbeat/rack'
require 'opbeat/interfaces/message'
require 'opbeat/interfaces/exception'
require 'opbeat/interfaces/stack_trace'
require 'opbeat/interfaces/http'

require 'opbeat/integrations/delayed_job'
require 'opbeat/integrations/sidekiq'

require 'opbeat/railtie' if defined?(::Rails::Railtie)


module Opbeat
  class << self
    # The client object is responsible for delivering formatted data to the Opbeat server.
    # Must respond to #send_event. See Opbeat::Client.
    attr_accessor :client

    # A Opbeat configuration object. Must act like a hash and return sensible
    # values for all Opbeat configuration options. See Opbeat::Configuration.
    attr_writer :configuration

    def logger
      @logger ||= Logger.new
    end

    # Tell the log that the client is good to go
    def report_ready
      self.logger.info "Opbeat #{VERSION} ready to catch errors"
    end

    # The configuration object.
    # @see Opbeat.configure
    def configuration
      @configuration ||= Configuration.new
    end

    # Call this method to modify defaults in your initializers.
    #
    # @example
    #   Opbeat.configure do |config|
    #     config.server = 'http://...'
    #   end
    def configure(silent = false)
      yield(configuration)
      self.client = Client.new(configuration)
      report_ready unless silent
      self.client
    end

    # Send an event to the configured Opbeat server
    #
    # @example
    #   evt = Opbeat::Event.new(:message => "An error")
    #   Opbeat.send(evt)
    def send(evt)
      @client.send_event(evt) if @client
    end

    # Capture and process any exceptions from the given block, or globally if
    # no block is given
    #
    # @example
    #   Opbeat.capture do
    #     MyApp.run
    #   end
    def capture(&block)
      if block
        begin
          block.call
        rescue Error => e
          raise # Don't capture Opbeat errors
        rescue Exception => e
          self.captureException(e)
          raise
        end
      else
        # Install at_exit hook
        at_exit do
          if $!
            logger.debug "Caught a post-mortem exception: #{$!.inspect}"
            self.capture_exception($!)
          end
        end
      end
    end

    def capture_exception(exception, options={})
      exception.set_backtrace caller unless exception.backtrace
      if (evt = Event.from_exception(exception, options))
        if self.configuration.async?
          self.configuration.async.call(evt)
        else
          send(evt)
        end
      end
    end

    def capture_rack_exception(exception, env, options={})
      exception.set_backtrace caller unless exception.backtrace
      if (evt = Event.from_rack_exception(exception, env, options))
        if self.configuration.async?
          self.configuration.async.call(evt)
        else
          send(evt)
        end
      end
    end

    def capture_message(message, options={})
      if (evt = Event.from_message(message, caller, options))
        if self.configuration.async?
          self.configuration.async.call(evt)
        else
          send(evt)
        end
      end
    end

    def set_context(options={})
      Event.set_context(options)
    end

    alias :captureException :capture_exception
    alias :captureMessage :capture_message
  end
end
