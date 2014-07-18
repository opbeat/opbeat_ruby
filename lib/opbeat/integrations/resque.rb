begin
  require 'resque'
rescue LoadError
end

if defined?(Resque)

  module Resque
    module Failure
      # Failure backend for Opbeat
      class Opbeat < Base
        # @override (see Resque::Failure::Base#save)
        # @param (see Resque::Failure::Base#save)
        # @return (see Resque::Failure::Base#save)
        def save
          ::Opbeat.captureException(exception)
        end
      end
    end
  end
  
end
