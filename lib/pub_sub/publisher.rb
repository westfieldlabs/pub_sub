module PubSub
  class Publisher
    class << self
      def publish(message, async: false, custom_topic: PubSub.service_identifier)
        if async
          publish_asynchronously(message, custom_topic)
        else
          publish_synchronously(message, custom_topic)
        end
      end

      def publish_asynchronously(message, custom_topic)
        Thread.new do
          publish_synchronously(message, custom_topic)
        end
      end

      def publish_synchronously(message, topic_name)
        Breaker.run do
          _topic_arn = topic_arn(topic_name)
          result = sns.publish(
            topic_arn: _topic_arn,
            message: message
          ).message_id
          PubSub.logger.debug "PubSub [#{PubSub.config.service_name}] published to #{topic_name} message #{result}"
          result
        end
      end

      private

      def sns
        Aws::SNS::Client.new(region: Breaker.current_region)
      end

      def topic_arn(topic_name)
        Breaker.run do
          sns.create_topic(name: topic_name).topic_arn
        end
      end

    end
  end
end
