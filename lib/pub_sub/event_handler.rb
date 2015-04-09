module PubSub
  class EventHandler
    attr_accessor :message

    def initialize(message)
      @message = message
    end

    def process
      error_message = '`process` must be overridden in subclass'
      fail NotImplementedError, error_message
    end

    def data
      Hashie::Mash.new(@message['data'])
    end
  end
end
