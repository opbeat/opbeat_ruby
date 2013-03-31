module Opbeat
  # Middleware for Rack applications. Any errors raised by the upstream
  # application will be delivered to Opbeat and re-raised.
  #
  # Synopsis:
  #
  #   require 'rack'
  #   require 'opbeat'
  #
  #   Opbeat.configure do |config|
  #     config.server = 'http://my_dsn'
  #   end
  #
  #   app = Rack::Builder.app do
  #     use Opbeat::Rack
  #     run lambda { |env| raise "Rack down" }
  #   end
  #
  # Use a standard Opbeat.configure call to configure your server credentials.
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        response = @app.call(env)
      rescue Error => e
        raise # Don't capture Opbeat errors
      rescue Exception => e
        evt = Event.capture_rack_exception(e, env)
        Opbeat.send(evt)
        raise
      end

      if env['rack.exception']
        evt = Event.capture_rack_exception(env['rack.exception'], env)
        Opbeat.send(evt) if evt
      end

      response
    end
  end
end
