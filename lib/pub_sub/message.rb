module PubSub
  class Message
    def initialize(payload)
      content = JSON.parse(payload)
      if content.is_a?(Hash) && content.has_key?('Message')
        # Handle the RawMessageDelivery attribute on the subscription being
        # set to false
        content = JSON.parse(content['Message'])
      end
      @payload = content
    end

    def process
      begin
        validate_message!
      rescue PubSub::ServiceUnknown => e
        return
      end
      handler.process(data)
    end

    def validate_message!
      messages = PubSub.config.subscriptions[sender]
      if messages.blank?
        warning = "#{PubSub.config.service_name} received a message from #{sender} but no matching subscription exists for that sender"
        PubSub.logger.warn warning
        raise PubSub::ServiceUnknown, warning
      elsif !messages.include?(type)
        error = "We received a message from #{sender} but it was of unknown type #{type}"
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
