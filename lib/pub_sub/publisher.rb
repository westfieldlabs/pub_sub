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
        Breaker.execute do
          _topic_arn = topic_arn(topic)
          result = sns.publish(
            topic_arn: _topic_arn,
            message: message
          ).message_id
          PubSub.logger.log "PubSub [#{PubSub.config.service_name}] published to #{_topic_arn} message #{result}"
          result
        end
      end

      private

      def sns
        Aws::SNS::Client.new(region: PubSub.config.current_region)
      end

      def topic_arn(topic)
        Breaker.execute do
          sns.create_topic(name: topic).topic_arn
        end
      end

    end
  end
end
