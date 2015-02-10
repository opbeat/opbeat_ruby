require 'openssl'
require 'uri'
require 'net/http'
require 'multi_json'

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

    USER_AGENT = "opbeat-ruby/#{Opbeat::VERSION}"

    attr_accessor :configuration
    attr_accessor :state

    def initialize(conf)
      raise Error.new('No server specified') unless conf.server
      raise Error.new('No secret token specified') unless conf.secret_token
      raise Error.new('No organization ID specified') unless conf.organization_id
      raise Error.new('No app ID specified') unless conf.app_id

      @configuration = conf
      @state = ClientState.new conf
      @processors = conf.processors.map { |p| p.new(self) }
      @base_path = "/api/v1/organizations/#{conf.organization_id}/apps/#{conf.app_id}"
      @auth_header = 'Bearer ' + conf.secret_token
    end

    def conn
      @conn ||= begin
        Opbeat.logger.debug "Initializing connection to #{self.configuration.server}"
        uri = URI.parse(self.configuration.server)
        conn = Net::HTTP.new(uri.host, uri.port)
        conn.read_timeout = conn.open_timeout = self.configuration.timeout if self.configuration.timeout
        conn.open_timeout = self.configuration.open_timeout if self.configuration.open_timeout
        conn.keep_alive_timeout = self.configuration.keep_alive_timeout if self.configuration.keep_alive_timeout
        conn.use_ssl = true
        conn.verify_mode = self.configuration.ssl_verification ?
          OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT :
          OpenSSL::SSL::VERIFY_NONE
        conn
      end
    end

    def encode(event)
      event_hash = event.to_hash

      @processors.each do |p|
        event_hash = p.process(event_hash)
      end

      return MultiJson.encode(event_hash)
    end

    def send(url_postfix, message)
      begin
        req = Net::HTTP::Post.new(@base_path + url_postfix)
        req.body = self.encode(message)
        req.add_field('Authorization', @auth_header)
        req.add_field('Content-Type', 'application/json')
        req.add_field('Content-Length', req.body.bytesize)
        req.add_field('User-Agent', USER_AGENT)
        response = self.conn.request(req)
        code = response.code.to_i
        unless code.between?(200, 299)
          raise Error.new("Error from Opbeat server (#{code}): #{response.body}")
        end
      rescue
        @state.set_fail
        raise
      end

      @state.set_success
      response
    end

    def send_event(event)
      return unless configuration.send_in_current_environment?
      unless state.should_try?
        Opbeat.logger.info "Temporarily skipping sending to Opbeat due to previous failure."
        return
      end

      # Set the organization ID correctly
      event.organization = self.configuration.organization_id
      event.app = self.configuration.app_id
      Opbeat.logger.debug "Sending event to Opbeat"
      response = send("/errors/", event)
      if response.status.between?(200, 299)
        Opbeat.logger.info "Event logged successfully at " + response.headers["location"].to_s
      end
      response
    end

    def send_release(release)
      Opbeat.logger.debug "Sending release to Opbeat"
      send("/releases/", release)
    end
  end

end
