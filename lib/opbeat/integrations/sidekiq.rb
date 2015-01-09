begin
  require 'sidekiq'
rescue LoadError
end

if defined? Sidekiq
  module Opbeat
    module Integrations
      class Sidekiq
        def call(worker, msg, queue)
          begin
            yield
          rescue Exception => ex
            raise ex if [Interrupt, SystemExit, SignalException].include? ex.class
            ::Opbeat.capture_exception(ex)
            raise
          end
        end
      end
    end
  end

  ::Sidekiq.configure_server do |config|
    if ::Sidekiq::VERSION < '3'
      config.server_middleware do |chain|
        chain.add ::Opbeat::Integrations::Sidekiq
      end
    else
      config.error_handlers << Proc.new { |ex, ctx| ::Opbeat.capture_exception(ex) }
    end
  end
end
