module PubSub
  class Subscriber
    def self.subscribe
      new.subscribe
    end

    def subscribe
      # Ensure our own topic has been created
      PubSub.config.subscriptions.keys.each do |service_identifier|
        subscribe_to_service(service_identifier)
      end
    end

    def subscribe_to_service(service_identifier)
      topic = Aws::SNS::Topic.new(sns.create_topic(name: service_identifier).topic_arn)
      queue_data = Aws::SQS::Client.new.get_queue_attributes(queue_url: Queue.new.queue_url, attribute_names: ["QueueArn"])
      queue_arn = queue_data.attributes["QueueArn"]
      topic.subscribe(endpoint: queue_arn, protocol: 'sqs')
      PubSub.logger.info "Subscribed #{queue_arn} to #{topic.arn}"
    end

    private

    def sns
      @sns ||= Aws::SNS::Client.new
    end
  end
end
