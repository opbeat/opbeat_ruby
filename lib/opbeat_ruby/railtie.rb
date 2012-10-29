require 'opbeat_ruby'
require 'rails'

module OpbeatRuby
  class Railtie < ::Rails::Railtie
    initializer "opbeat_ruby.use_rack_middleware" do |app|
      app.config.middleware.insert 0, "OpbeatRuby::Rack"
    end
    config.after_initialize do
      OpbeatRuby.configure(true) do |config|
        config.logger ||= ::Rails.logger
      end

      if defined?(::ActionDispatch::DebugExceptions)
        require 'opbeat_ruby/rails/middleware/debug_exceptions_catcher'
        ::ActionDispatch::DebugExceptions.send(:include, OpbeatRuby::Rails::Middleware::DebugExceptionsCatcher)
      elsif defined?(::ActionDispatch::ShowExceptions)
        require 'opbeat_ruby/rails/middleware/debug_exceptions_catcher'
        ::ActionDispatch::ShowExceptions.send(:include, OpbeatRuby::Rails::Middleware::DebugExceptionsCatcher)
      end
    end
  end
end
