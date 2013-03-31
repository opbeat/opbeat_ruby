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
require 'opbeat/processors/sanitizedata'

require 'opbeat/railtie' if defined?(Rails::Railtie)

module Opbeat
  class << self
    # The client object is responsible for delivering formatted data to the Opbeat server.
    # Must respond to #send. See Opbeat::Client.
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
      @client.send(evt) if @client
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
            self.captureException($!)
          end
        end
      end
    end

    def captureException(exception)
      evt = Event.capture_exception(exception)
      send(evt) if evt
    end

    def captureMessage(message)
      evt = Event.capture_message(message)
      send(evt) if evt
    end

  end
end
