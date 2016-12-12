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

          message_type = JSON.parse(message)['type'] rescue "unknown"

          logging_details = {
            service_name: PubSub.config.service_name,
            message_type: message_type,
            message_id: result,
            topic_arn: _topic_arn
          }.to_json

          PubSub.logger.log "[PubSub] published message: #{logging_details}"
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
