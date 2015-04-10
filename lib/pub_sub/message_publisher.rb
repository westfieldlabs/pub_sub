module PubSub
  module MessagePublisher
    def publish
      Publisher.publish(message_json)
    end

    def message_type
      self.class.name.underscore
    end

    def message_json
      {
        sender: PubSub.service_identifier,
        type: message_type,
        data: message_data
      }
    end
  end
end
