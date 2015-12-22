module PubSub
  class Publisher
    class << self
      def publish(message, async: false, topic: PubSub.service_identifier)
        if async
          publish_asynchronously(message, topic)
        else
          publish_synchronously(message, topic)
        end
      end

      def publish_asynchronously(message, topic)
        Thread.new do
          publish_synchronously(message, topic)
        end
      end

      def publish_synchronously(message, topic)
        Breaker.run do
          _topic_arn = topic_arn(topic)
          result = sns.publish(
            topic_arn: _topic_arn,
            message: message
          ).message_id
          PubSub.logger.debug "PubSub [#{PubSub.config.service_name}] published to #{topic} message #{result}"
          result
        end
      end

      private

      def sns
        Aws::SNS::Client.new(region: Breaker.current_region)
      end

      def topic_arn(topic)
        Breaker.run do
          sns.create_topic(name: topic).topic_arn
        end
      end

    end
  end
end
