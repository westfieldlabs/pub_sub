module PubSub
  module MessagePublisher
    def publish(async: false)
      Publisher.publish(message_json, async: async)
    end

    def message_type
      self.class.name.underscore
    end

    def message_json
      {
        sender: PubSub.service_identifier,
        type: message_type,
        data: message_data
      }.to_json
    end
  end
end
