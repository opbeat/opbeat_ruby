module OpbeatRuby
  module Rails
    module Middleware
      module DebugExceptionsCatcher
        def self.included(base)
          base.send(:alias_method_chain, :render_exception, :raven)
        end

        def render_exception_with_raven(env, exception)
          begin
            evt = OpbeatRuby::Event.capture_rack_exception(exception, env)
            OpbeatRuby.send(evt) if evt
          rescue
            ::Rails::logger.debug "Error capturing or sending exception #{$!}"
          end

          render_exception_without_raven(env, exception)
        end
      end
    end
  end
end
