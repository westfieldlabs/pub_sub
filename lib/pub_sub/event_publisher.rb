module PubSub
  class EventPublisher < Hashie::Mash
    def self.publish!(data)
      new.publish!(data)
    end

    def publish!(data)
      merge!(
        sender: PubSub.config.service_name,
        type: event_type,
        data: data
      )
      broadcast
    end

    def event_type
      self.class.name.underscore
    end

    def broadcast
      Publisher.topic.publish(to_json)
    end
  end
end
