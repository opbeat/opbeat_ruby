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
        Opbeat.capture_rack_exception(e, env)
        raise
      end

      error = env['rack.exception'] || env['sinatra.error']

      if error
        Opbeat.capture_rack_exception(error, env)
      end

      response
    end
  end
end
