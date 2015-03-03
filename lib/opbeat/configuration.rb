module Opbeat
  class Configuration

    # Base URL of the Opbeat server
    attr_accessor :server

    # Secret access token for authentication with Opbeat
    attr_accessor :secret_token

    # Organization ID to use with Opbeat
    attr_accessor :organization_id

    # App ID to use with Opbeat
    attr_accessor :app_id

    # Logger to use internally
    attr_accessor :logger

    # Number of lines of code context to capture, or nil for none
    attr_accessor :context_lines

    # Whitelist of environments that will send notifications to Opbeat
    attr_accessor :environments

    # Which exceptions should never be sent
    attr_accessor :excluded_exceptions

    # Processors to run on data before sending upstream
    attr_accessor :processors

    # Timeout when waiting for the server to return data in seconds
    attr_accessor :timeout

    # Timout when opening connection to the server
    attr_accessor :open_timeout

    # Backoff multipler
    attr_accessor :backoff_multiplier

    # Should the SSL certificate of the server be verified?
    attr_accessor :ssl_verification

    attr_reader :current_environment

    attr_accessor :user_controller_method

    # Optional Proc to be used to send events asynchronously
    attr_reader :async

    def initialize
      self.server = ENV['OPBEAT_SERVER'] || "https://intake.opbeat.com"
      self.secret_token = ENV['OPBEAT_SECRET_TOKEN'] if ENV['OPBEAT_SECRET_TOKEN']
      self.organization_id = ENV['OPBEAT_ORGANIZATION_ID'] if ENV['OPBEAT_ORGANIZATION_ID']
      self.app_id = ENV['OPBEAT_APP_ID'] if ENV['OPBEAT_APP_ID']
      @context_lines = 3
      self.environments = %w[ development production default ]
      self.current_environment = (defined?(::Rails) && ::Rails.env) || ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'default'
      self.excluded_exceptions = []
      self.processors = [Opbeat::Processor::SanitizeData]
      self.timeout = 1
      self.open_timeout = 1
      self.backoff_multiplier = 2
      self.ssl_verification = true
      self.user_controller_method = 'current_user'
      self.async = false
    end

    # Allows config options to be read like a hash
    #
    # @param [Symbol] option Key for a given attribute
    def [](option)
      send(option)
    end

    def current_environment=(environment)
      @current_environment = environment.to_s
    end

    def send_in_current_environment?
      environments.include? current_environment
    end

    def async=(value)
      raise ArgumentError.new("async must be callable (or false to disable)") unless (value == false || value.respond_to?(:call))
      @async = value
    end

    alias_method :async?, :async

  end
end
