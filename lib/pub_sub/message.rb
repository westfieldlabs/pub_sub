module PubSub
  class Message
    def initialize(payload)
      @payload = JSON.parse(JSON.parse(payload)['Message'])
    end

    def process
      validate_message!
      handler.process(data)
    end

    def validate_message!
      messages = PubSub.config.subscriptions[sender]
      if messages.nil?
        error = "We received a message from #{sender} but we do " \
                'not subscribe to that service.'
        fail PubSub::ServiceUnknown, error
      end

      unless messages.include?(type)
        error = "We received a message from #{sender} but it was " \
                "of unknown type #{type}."
        fail PubSub::MessageTypeUnknown, error
      end
    end

    private

    # Service where this message originated
    def sender
      @payload['sender']
    end

    def type
      @payload['type']
    end

    def data
      @payload['data']
    end

    def handler
      type.camelize.constantize
    end
  end
end
