module PubSub
  class Subscriber
    def self.subscribe
      new.subscribe
    end

    def subscribe
      PubSub.config.subscriptions.keys.each do |service_identifier|
        subscribe_to_service(service_identifier)
      end
    end

    def subscribe_to_service(service_identifier)
      PubSub.logger.info("Subscribing to #{service_identifier}")
      sns.create_topic(name: service_identifier)
    end

    def list_subscriptions
      sns.list_subscriptions.subscriptions
    end

    private

    def sns
      @sns ||= Aws::SNS::Client.new
    end
  end
end
