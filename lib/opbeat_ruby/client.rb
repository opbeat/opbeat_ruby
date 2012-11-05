require 'openssl'
require 'uri'
require 'multi_json'
require 'faraday'

require 'opbeat_ruby/version'
require 'opbeat_ruby/error'

module OpbeatRuby

  class Client

    PROTOCOL_VERSION = '1.0'
    USER_AGENT = "opbeat_ruby/#{OpbeatRuby::VERSION}"
    AUTH_HEADER_KEY = 'Authorization'

    attr_accessor :configuration

    def initialize(configuration)
      @configuration = configuration
    end

    def conn
      # Error checking
      raise Error.new('No server specified') unless self.configuration[:server]
      raise Error.new('No access token specified') unless self.configuration[:access_token]
      raise Error.new('No project ID specified') unless self.configuration[:project_id]

      OpbeatRuby.logger.debug "Opbeat client connecting to #{self.configuration[:server]}"
      @url =  self.configuration[:server] + '/api/v0/project/' + self.configuration[:project_id] + "/error/"
      @conn ||=  Faraday.new(:url => @url) do |builder|
        builder.adapter  Faraday.default_adapter
      end
    end

    def generate_auth_header(data)
      'Bearer ' + self.configuration[:access_token]
    end

    def send(event)
      return unless configuration.send_in_current_environment?

      # Set the project ID correctly
      event.project = self.configuration[:project_id]
      OpbeatRuby.logger.debug "Sending event #{event.id} to Opbeat"
      
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
