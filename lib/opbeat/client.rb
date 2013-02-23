require 'openssl'
require 'uri'
require 'multi_json'
require 'faraday'

require 'opbeat/version'
require 'opbeat/error'

module Opbeat

  class Client

    PROTOCOL_VERSION = '1.0'
    USER_AGENT = "opbeat/#{Opbeat::VERSION}"
    AUTH_HEADER_KEY = 'Authorization'

    attr_accessor :configuration

    def initialize(configuration)
      @configuration = configuration
    end

    def conn
      # Error checking
      raise Error.new('No server specified') unless self.configuration[:server]
      raise Error.new('No secret token specified') unless self.configuration[:secret_token]
      raise Error.new('No organization ID specified') unless self.configuration[:organization_id]
      raise Error.new('No app ID specified') unless self.configuration[:app_id]

      Opbeat.logger.debug "Opbeat client connecting to #{self.configuration[:server]}"
      @url =  self.configuration[:server] + "/api/v1/organizations/" + self.configuration[:organization_id] +  "/apps/" + self.configuration[:app_id] + "/errors/"
      @conn ||=  Faraday.new(:url => @url) do |builder|
        builder.adapter  Faraday.default_adapter
      end
    end

    def generate_auth_header(data)
      'Bearer ' + self.configuration[:secret_token]
    end

    def send(event)
      return unless configuration.send_in_current_environment?

      # Set the project ID correctly
      event.organization = self.configuration[:organization_id]
      event.app = self.configuration[:app_id]
      Opbeat.logger.debug "Sending event #{event.id} to Opbeat"
      
      response = self.conn.post @url do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = MultiJson.encode(event.to_hash)
        req.headers[AUTH_HEADER_KEY] = self.generate_auth_header(req.body)
        req.headers["User-Agent"] = USER_AGENT
      end
      raise Error.new("Error from Opbeat server (#{response.status}): #{response.body}") unless response.status == 202
      response
    end

  end

end
