begin
  require 'delayed_job'
rescue LoadError
end

# Based on the Sentry equivalent.
if defined?(Delayed)

  module Delayed
    module Plugins
      class Opbeat < ::Delayed::Plugin
        callbacks do |lifecycle|
          lifecycle.around(:invoke_job) do |job, *args, &block|
            begin
              # Forward the call to the next callback in the callback chain
              block.call(job, *args)

            rescue Exception => exception
              # Log error to Opbeat
              ::Opbeat.capture_exception(exception)
              # Make sure we propagate the failure!
              raise exception
            end
          end
        end
      end
    end
  end

  # Register DelayedJob Opbeat plugin
  Delayed::Worker.plugins << Delayed::Plugins::Opbeat
end