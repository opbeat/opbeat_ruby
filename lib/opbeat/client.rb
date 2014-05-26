require 'openssl'
require 'uri'
require 'multi_json'
require 'faraday'

require 'opbeat/version'
require 'opbeat/error'

module Opbeat

  class ClientState
    def initialize(configuration)
      @configuration = configuration
      @retry_number = 0
      @last_check = Time.now
    end

    def should_try?
      return true if @status == :online
        
      interval = ([@retry_number, 6].min() ** 2) * @configuration[:backoff_multiplier]
      return true if Time.now - @last_check > interval

      false
    end

    def set_fail
      @status = :error
      @retry_number += 1
      @last_check = Time.now
    end

    def set_success
      @status = :online
      @retry_number = 0
      @last_check = nil
    end
  end

  class Client

    PROTOCOL_VERSION = '1.0'
    USER_AGENT = "opbeat/#{Opbeat::VERSION}"
    AUTH_HEADER_KEY = 'Authorization'

    attr_accessor :configuration
    attr_accessor :state

    def initialize(configuration)
      @configuration = configuration
      @state = ClientState.new configuration
      @processors = configuration.processors.map { |p| p.new(self) }
    end

    def conn
      # Error checking
      raise Error.new('No server specified') unless self.configuration[:server]
      raise Error.new('No secret token specified') unless self.configuration[:secret_token]
      raise Error.new('No organization ID specified') unless self.configuration[:organization_id]
      raise Error.new('No app ID specified') unless self.configuration[:app_id]

      Opbeat.logger.debug "Opbeat client connecting to #{self.configuration[:server]}"
      @url =  self.configuration[:server] + "/api/v1/organizations/" + self.configuration[:organization_id] +  "/apps/" + self.configuration[:app_id] + "/errors/"
      @conn ||=  Faraday.new(:url => @url, :ssl => {:verify => self.configuration.ssl_verification}) do |builder|
        builder.adapter  Faraday.default_adapter
      end

      @conn.options[:timeout] = self.configuration[:timeout]
      @conn.options[:open_timeout] = self.configuration[:open_timeout]
      @conn
    end

    def generate_auth_header(data)
      'Bearer ' + self.configuration[:secret_token]
    end

    def encode(event)
      event_hash = event.to_hash
      
      @processors.each do |p|
        event_hash = p.process(event_hash)
      end
      
      return MultiJson.encode(event_hash)
    end

    def send(event)
      return unless state.should_try?

      # Set the organization ID correctly
      event.organization = self.configuration[:organization_id]
      event.app = self.configuration[:app_id]
      Opbeat.logger.debug "Sending event #{event.id} to Opbeat"
      
      begin
        response = self.conn.post @url do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = self.encode(event)
          req.headers[AUTH_HEADER_KEY] = self.generate_auth_header(req.body)
          req.headers["User-Agent"] = USER_AGENT
        end

        unless response.status == 202
          raise Error.new("Error from Opbeat server (#{response.status}): #{response.body}")
        end
      rescue
        @state.set_fail
        raise
      end

      @state.set_success
      response
    end

  end

end
