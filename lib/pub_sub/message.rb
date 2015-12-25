module PubSub
  class Message

    def initialize(payload)
      begin
        payload_as_json = JSON.parse(payload)
        @message_id = payload_as_json['MessageId']
        if payload_as_json.is_a?(Hash) && payload_as_json.has_key?("Message")
          # RawMessageDelivery=false
          @payload = JSON.parse(payload_as_json['Message'])
        else
          # RawMessageDelivery=true
          @payload = payload_as_json
        end
      rescue => e
        PubSub.logger.error "#{e.message}. Payload: #{payload.inspect}"
        raise
      end
    end

    def process
      begin
        validate_message!
        PubSub.logger.debug "Processing message #{@message_id} with #{handler}"
        handler.process(data)
      rescue PubSub::ServiceUnknown, PubSub::MessageTypeUnknown => e
        PubSub.logger.error e.message
      end
    end

    def validate_message!
      messages = PubSub.config.subscriptions[sender]
      if messages.nil? || messages.empty?
        warning = "#{PubSub.config.service_name} received a message from #{sender} but no matching subscription exists for that sender. Available senders are: #{PubSub.config.subscriptions.keys}"
        fail PubSub::ServiceUnknown, warning
      elsif !messages.include?(type)
        error = "#{PubSub.config.service_name} received a message from #{sender} but it was of unknown type #{type}. Available types are: #{messages}"
        fail PubSub::MessageTypeUnknown, error
      end
    end

    private

    # Service where this message originated
    def sender
      @payload['sender']
    end

    # Type of message this is
    def type
      @payload['type']
    end

    # Data contained the the payload
    def data
      @payload['data']
    end

    # Guess the handler based on conventions
    # Eg deal_update -> DealUpdate
    def handler
      @handler ||= type.camelize.constantize
    end
  end
end
