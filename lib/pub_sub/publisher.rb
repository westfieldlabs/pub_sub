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
      Thread.new do
        message_id = publish_synchronously(message)
        PubSub.logger.info(
          "Message published asynchronously: #{message_id}"
        )
      end
    end

    def publish_synchronously(message)
      sns.publish(
        topic_arn: topic_arn,
        message: message
      ).message_id
    end

    def list_topics
      sns.list_topics.topics
    end

    private

    def sns
      @sns ||= Aws::SNS::Client.new
    end

    def topic_arn
      @topic_arn ||= begin
        sns.create_topic(name: topic_name).topic_arn
      end
    end

    def topic_name
      PubSub.service_identifier
    end
  end
end
