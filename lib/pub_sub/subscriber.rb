module PubSub
  class Subscriber
    attr_accessor :sns

    def self.subscribe!
      new.subscribe!
    end

    def sns
      @sns ||= AWS::SNS.new
    end

    def subscribe!
      PubSub.config.subscriptions.each do |service_name|
        subscribe_to_service(service_name)
      end
    end

    def subscribe_to_service(service_name)
      topic_name = topic_name(service_name)
      PubSub.logger.info("Subscribing to #{topic_name}")
      sns.topics.create(topic_name)
    end

    private

    def topic_name(service_name)
      "#{service_name}-service-#{PubSub.env_suffix}"
    end
  end
end
