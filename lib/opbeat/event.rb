require 'rubygems'
require 'socket'

require 'opbeat/error'
require 'opbeat/linecache'

module Opbeat

  class Event

    LOG_LEVELS = {
      "debug" => "debug",
      "info" => "info",
      "warn" => "warn",
      "warning" => "warn",
      "error" => "error",
    }

    BACKTRACE_RE = /^(.+?):(\d+)(?::in `(.+?)')?$/

    attr_reader :id
    attr_accessor :organization, :app, :message, :timestamp, :level
    attr_accessor :logger, :culprit, :hostname, :modules, :extra, :user
    attr_accessor :environment

    def initialize(options={}, configuration=nil, &block)
      @configuration = configuration || Opbeat.configuration
      @interfaces = {}

      @id = options[:id]
      @message = options[:message]
      @timestamp = options[:timestamp] || Time.now.utc
      @level = options[:level] || :error
      @logger = options[:logger] || 'root'
      @culprit = options[:culprit]
      @environment = @configuration[:current_environment]
      @extra = options[:extra]
      @user = options[:user]

      # Try to resolve the hostname to an FQDN, but fall back to whatever the load name is
      hostname = Socket.gethostname
      hostname = Socket.gethostbyname(hostname).first rescue hostname
      @hostname = options[:hostname] || hostname

      block.call(self) if block

      # Some type coercion
      @timestamp = @timestamp.strftime('%Y-%m-%dT%H:%M:%S') if @timestamp.is_a?(Time)
      @level = LOG_LEVELS[@level.to_s.downcase] if @level.is_a?(String) || @level.is_a?(Symbol)

      # Basic sanity checking
      raise Error.new('A message is required for all events') unless @message && !@message.empty?
      raise Error.new('A timestamp is required for all events') unless @timestamp
    end

    def interface(name, value=nil, &block)
      int = Opbeat::find_interface(name)
      Opbeat.logger.info "Unknown interface: #{name}" unless int
      raise Error.new("Unknown interface: #{name}") unless int
      @interfaces[int.name] = int.new(value, &block) if value || block
      @interfaces[int.name]
    end

    def [](key)
      interface(key)
    end

    def []=(key, value)
      interface(key, value)
    end

    def to_hash
      data = {
        'message' => self.message,
        'timestamp' => self.timestamp,
        'level' => self.level,
        'logger' => self.logger,
      }
      data['client_supplied_id'] = self.id if self.id
      data['culprit'] = self.culprit if self.culprit
      data['machine'] = {'hostname' => self.hostname } if self.hostname
      data['environment'] = self.environment if self.environment
      data['extra'] = self.extra if self.extra
      if self.user
        data['user'] = self.user
        if self.user[:id] or self.user[:email] or self.user[:username]
          data['user'][:is_authenticated] = true
        end
        data['user'][:is_authenticated] = false if !data['user'][:is_authenticated]
      end
      @interfaces.each_pair do |name, int_data|
        data[name] = int_data.to_hash
      end
      data
    end

    def self.from_exception(exc, options={}, &block)
      configuration = Opbeat.configuration
      if exc.is_a?(Opbeat::Error)
        # Try to prevent error reporting loops
        Opbeat.logger.info "Refusing to capture Opbeat error: #{exc.inspect}"
        return nil
      end
      if configuration[:excluded_exceptions].include? exc.class.name
        Opbeat.logger.info "User excluded error: #{exc.inspect}"
        return nil
      end
      options = self.merge_context(options)
      self.new(options, configuration) do |evt|
        evt.message = "#{exc.class.to_s}: #{exc.message}"
        evt.level = :error
        evt.parse_exception(exc)
        evt.interface :stack_trace do |int|
          int.frames = exc.backtrace.reverse.map do |trace_line|
            int.frame {|frame| evt.parse_backtrace_line(trace_line, frame) }
          end
          evt.culprit = evt.get_culprit(int.frames)
        end
        block.call(evt) if block
      end
    end

    def self.from_rack_exception(exc, rack_env, options={}, &block)
      from_exception(exc, options) do |evt|
        evt.interface :http do |int|
          int.from_rack(rack_env)
        end

        if not evt.user
          controller = rack_env["action_controller.instance"]
          user_method_name = Opbeat.configuration.user_controller_method
          if controller and controller.respond_to? user_method_name
            user_obj = controller.send user_method_name
            evt.from_user_object(user_obj)
          end
        end        

        block.call(evt) if block
      end
    end

    def self.from_message(message, stack, options={})
      configuration ||= Opbeat.configuration
      options = self.merge_context(options)
      self.new(options, configuration) do |evt|
        evt.message = message
        evt.level = :error
        evt.interface :message do |int|
          int.message = message
        end
        evt.interface :stack_trace do |int|
          int.frames = stack.reverse.map do |trace_line|
            int.frame {|frame| evt.parse_backtrace_line(trace_line, frame) }
          end
        end
      end
    end

    def self.set_context(options={})
      Thread.current["_opbeat_context"] = options
    end

    def get_culprit(frames)
        lastframe = frames[-2]
        "#{lastframe.filename} in #{lastframe.function}" if lastframe
    end

    def parse_exception(exception)
      interface(:exception) do |int|
        int.type = exception.class.to_s
        int.value = exception.message
        int.module = exception.class.to_s.split('::')[0...-1].join('::')
      end
    end

    def parse_backtrace_line(line, frame)
      md = BACKTRACE_RE.match(line)
      raise Error.new("Unable to parse backtrace line: #{line.inspect}") unless md
      frame.abs_path = md[1]
      frame.lineno = md[2].to_i
      frame.function = md[3] if md[3]
      frame.filename = strip_load_path_from(frame.abs_path)
      if context_lines = @configuration[:context_lines]
        frame.pre_context, frame.context_line, frame.post_context = \
          get_contextlines(frame.abs_path, frame.lineno, context_lines)
      end
      frame
    end

    def from_user_object(user_obj)
      @user = {} if not @user
      @user[:id] = user_obj.send(:id) rescue nil
      @user[:email] = user_obj.send(:email) rescue nil
      @user[:username] = user_obj.send(:username) rescue nil
    end

    private

    def self.merge_context(options={})
      context_options = Thread.current["_opbeat_context"] || {}
      context_options.merge(options)
    end


    # Because linecache can go to hell
    def self._source_lines(path, from, to)
    end

    def get_contextlines(path, line, context)
      lines = (2 * context + 1).times.map do |i|
        Opbeat::LineCache::getline(path, line - context + i)
      end
      [lines[0..(context-1)], lines[context], lines[(context+1)..-1]]
    end

    def strip_load_path_from(path)
      prefix = $:.select {|s| path.start_with?(s.to_s)}.sort_by {|s| s.to_s.length}.last
      prefix ? path[prefix.to_s.chomp(File::SEPARATOR).length+1..-1] : path
    end
  end
end
