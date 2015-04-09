module PubSub
  class Message
    attr_accessor :message

    def initialize(message)
      @message = JSON.parse(message)
    end

    def process
      handler.process if processable?
    end

    def processable?
      if handler.nil?
        PubSub.logger.warning("No event handler found for #{type}.")
        nil
      elsif !handler.respond_to?(:process)
        PubSub.logger.error("Event handler #{type} missing process method.")
        nil
      else
        true
      end
    end

    private

    def type
      @message['type']
    end

    def handler
      type.camelize.constantize.new(@message)
    rescue NameError
      nil # No handler found
    end
  end
end
