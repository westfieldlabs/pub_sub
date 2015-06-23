module PubSub
  class Subscriber
    def self.subscribe
      new.subscribe
    end

    def subscribe
      topics = PubSub.config.subscriptions.keys.map do |service_identifier|
        subscribe_to_service(service_identifier)
      end
      set_queue_policy(topics.map(&:arn))
    end

    private

    def subscribe_to_service(service_identifier)
      topic = Aws::SNS::Topic.new(sns.create_topic(name: service_identifier).topic_arn)
      topic.subscribe(endpoint: queue_arn, protocol: 'sqs')
      PubSub.logger.info "Subscribed #{queue_arn} to #{topic.arn}"
      topic
    end

    def set_queue_policy(topic_arns)
      Aws::SQS::Client.new.set_queue_attributes(
        queue_url: queue_url,
        attributes: {
          Policy: JSON.generate(
            policy_attributes(topic_arns)
          )
        }
      )
    end

    delegate :queue_url, :queue_arn, to: :queue

    def policy_attributes(topic_arns)
      {
        Version: '2008-10-17',
        Id: "#{queue_arn}/SQSDefaultPolicy",
        Statement: [{
          Sid: "SendMessageTo##{queue_arn}",
          Effect: 'Allow',
          Principal: { 'AWS': '*' },
          Action: 'SQS:SendMessage',
          Resource: queue_arn,
          Condition: { ArnEquals: { 'aws:SourceArn': topic_arns } }
        }]
      }
    end

    def sns
      @sns ||= Aws::SNS::Client.new
    end

    def queue
      @queue ||= Queue.new
    end
  end
end
