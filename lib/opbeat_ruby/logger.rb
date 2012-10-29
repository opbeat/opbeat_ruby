module OpbeatRuby
  class Logger
    LOG_PREFIX = "** [OpbeatRuby] "

    [
      :fatal,
      :error,
      :warn,
      :info,
      :debug,
    ].each do |level|
      define_method level do |*args, &block|
        msg = args[0] # Block-level default args is a 1.9 feature
        msg ||= block.call if block
        logger = OpbeatRuby.configuration[:logger]
        logger.send(level, "#{LOG_PREFIX}#{msg}") if logger
      end
    end

  end
end
