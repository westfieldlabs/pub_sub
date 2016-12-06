module PubSub
  class Logger
    extend Forwardable

    def_delegators :@logger, :debug, :info, :warn, :error, :fatal, :unknown

    def initialize(logger)
      @logger = logger
    end

    def log(message, log_level=PubSub.config.log_level)
      @logger.public_send(log_level, message)
    end
  end
end
