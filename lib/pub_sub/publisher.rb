module PubSub
  class Publisher

    def self.publish(message, async: false)
      if async
        new.publish_asynchronously(message)
      else
        new.publish_synchronously(message)
      end
    end

    def self.topic
      new.topic
    end

    def publish_asynchronously(message)
      Thread.new { publish_synchronously(message) }
    end

    def publish_synchronously(message)
      topic.publish(message)
    end

    def list_topics
      sns.list_topics.topics
    end

    private

    def sns
      @sns ||= Aws::SNS::Client.new
    end

    def topic
      @topic ||= sns.create_topic(name: topic_name)
    end

    def topic_name
      PubSub.service_identifier
    end
  end
end
