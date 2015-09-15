module PubSub
  class Publisher
    class << self
      def publish(message, async: false)
        if async
          publish_asynchronously(message)
        else
          publish_synchronously(message)
        end
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
        Breaker.run do
          sns.publish(
            topic_arn: topic_arn,
            message: message
          ).message_id
        end
      end

      private

      def sns
        Aws::SNS::Client.new(region: Breaker.current_region)
      end

      def topic_arn
        Breaker.run do
          sns.create_topic(name: topic_name).topic_arn
        end
      end

      def topic_name
        PubSub.service_identifier
      end
    end
  end
end
