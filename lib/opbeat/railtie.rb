require 'opbeat'
require 'rails'

module Opbeat
  class Railtie < ::Rails::Railtie
    initializer "opbeat.use_rack_middleware" do |app|
      app.config.middleware.insert 0, "Opbeat::Rack"
    end
    config.after_initialize do
      Opbeat.configure(true) do |config|
        config.logger ||= ::Rails.logger
      end

      if defined?(::ActionDispatch::DebugExceptions)
        require 'opbeat/rails/middleware/debug_exceptions_catcher'
        ::ActionDispatch::DebugExceptions.send(:include, Opbeat::Rails::Middleware::DebugExceptionsCatcher)
      elsif defined?(::ActionDispatch::ShowExceptions)
        require 'opbeat/rails/middleware/debug_exceptions_catcher'
        ::ActionDispatch::ShowExceptions.send(:include, Opbeat::Rails::Middleware::DebugExceptionsCatcher)
      end
    end
    rake_tasks do
      require 'opbeat/tasks'
    end
  end
end
