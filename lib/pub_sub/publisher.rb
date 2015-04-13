module PubSub
  class Publisher
    include Singleton

    def self.publish(message, async: false)
      if async
        instance.publish_asynchronously(message)
      else
        instance.publish_synchronously(message)
      end
    end

    def publish_asynchronously(message)
      Thread.new { publish_synchronously(message) }
    end

    def publish_synchronously(message)
      topic.publish(message)
    end

    def self.topic
      instance.topic
    end

    private

    def sns
      @sns ||= AWS::SNS.new
    end

    def topic
      @topic ||= sns.topics.create(topic_name)
    end

    def topic_name
      PubSub.service_identifier
    end
  end
end
