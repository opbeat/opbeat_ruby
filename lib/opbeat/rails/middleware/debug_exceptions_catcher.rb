module Opbeat
  module Rails
    module Middleware
      module DebugExceptionsCatcher
        def self.included(base)
          base.send(:alias_method_chain, :render_exception, :opbeat)
        end

        def render_exception_with_opbeat(env, exception)
          begin
            evt = Opbeat::Event.from_rack_exception(exception, env)
            Opbeat.send(evt) if evt
          rescue
            ::Rails::logger.debug "Error capturing or sending exception #{$!}"
          end

          render_exception_without_opbeat(env, exception)
        end
      end
    end
  end
end
