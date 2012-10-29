require 'opbeat_ruby/version'
require 'opbeat_ruby/configuration'
require 'opbeat_ruby/logger'
require 'opbeat_ruby/client'
require 'opbeat_ruby/event'
require 'opbeat_ruby/rack'
require 'opbeat_ruby/interfaces/message'
require 'opbeat_ruby/interfaces/exception'
require 'opbeat_ruby/interfaces/stack_trace'
require 'opbeat_ruby/interfaces/http'
require 'opbeat_ruby/processors/sanitizedata'

require 'opbeat_ruby/railtie' if defined?(Rails::Railtie)

module OpbeatRuby
  class << self
    # The client object is responsible for delivering formatted data to the Sentry server.
    # Must respond to #send. See OpbeatRuby::Client.
    attr_accessor :client

    # A OpbeatRuby configuration object. Must act like a hash and return sensible
    # values for all OpbeatRuby configuration options. See OpbeatRuby::Configuration.
    attr_writer :configuration

    def logger
      @logger ||= Logger.new
    end

    # Tell the log that the client is good to go
    def report_ready
      self.logger.info "OpbeatRuby #{VERSION} ready to catch errors"
    end

    # The configuration object.
    # @see OpbeatRuby.configure
    def configuration
      @configuration ||= Configuration.new
    end

    # Call this method to modify defaults in your initializers.
    #
    # @example
    #   OpbeatRuby.configure do |config|
    #     config.server = 'http://...'
    #   end
    def configure(silent = false)
      yield(configuration)
      self.client = Client.new(configuration)
      report_ready unless silent
      self.client
    end

    # Send an event to the configured Sentry server
    #
    # @example
    #   evt = OpbeatRuby::Event.new(:message => "An error")
    #   OpbeatRuby.send(evt)
    def send(evt)
      @client.send(evt) if @client
    end

    # Capture and process any exceptions from the given block, or globally if
    # no block is given
    #
    # @example
    #   OpbeatRuby.capture do
    #     MyApp.run
    #   end
    def capture(&block)
      if block
        begin
          block.call
        rescue Error => e
          raise # Don't capture OpbeatRuby errors
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
