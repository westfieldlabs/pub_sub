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
      sns.topics.create(service_identifier)
    end

    private

    def sns
      @sns ||= AWS::SNS.new
    end
  end
end
