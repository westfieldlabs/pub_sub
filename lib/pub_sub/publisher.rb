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
          publish_synchronously(message)
        end
      end

      def publish_synchronously(message)
        Breaker.run do
          _topic_arn = topic_arn
          result = sns.publish(
            topic_arn: _topic_arn,
            message: message
          ).message_id
          PubSub.logger.debug "PubSub [#{PubSub.config.service_name}] published to #{_topic_arn} message #{result}"
          result
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
