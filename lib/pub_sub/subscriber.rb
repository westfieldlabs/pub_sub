module PubSub
  class Subscriber
    def self.subscribe
      new.subscribe
    end

    def subscribe
      PubSub.config.regions.each do |region|
        topics = PubSub.config.subscriptions.keys.map do |service_identifier|
          subscribe_to_service(service_identifier, region)
        end
        set_queue_policy(topics.map(&:arn), region)
      end
    end

    private

    def subscribe_to_service(service_identifier, region)
      topic = Aws::SNS::Topic.new(sns(region).create_topic(name: service_identifier).topic_arn, region: region)
      topic.subscribe(endpoint: queue_arn(region), protocol: 'sqs')
      PubSub.logger.info "Subscribed #{queue_arn(region)} to #{topic.arn}"
      topic
    end

    def set_queue_policy(topic_arns, region)
      Aws::SQS::Client.new(region: region).set_queue_attributes(
        queue_url: queue_url(region),
        attributes: {
          Policy: JSON.generate(
            policy_attributes(topic_arns, region)
          )
        }
      )
    end

    def policy_attributes(topic_arns, region)
      {
        Version: '2008-10-17',
        Id: "#{queue_arn(region)}/SQSDefaultPolicy",
        Statement: [{
          Sid: "SendMessageTo##{queue_arn(region)}",
          Effect: 'Allow',
          Principal: { 'AWS': '*' },
          Action: 'SQS:SendMessage',
          Resource: queue_arn(region),
          Condition: { ArnEquals: { 'aws:SourceArn': topic_arns } }
        }]
      }
    end

    def sns(region)
      Aws::SNS::Client.new(region: region)
    end

    def sqs(region)
      Aws::SQS::Client.new(region: region)
    end

    def queue_arn(region)
      sqs(region).get_queue_attributes(
          queue_url: queue_url(region), attribute_names: ["QueueArn"]
        ).attributes["QueueArn"]
    end

    def queue_url(region)
      sqs(region).create_queue(queue_name: PubSub.service_identifier).queue_url
    end
  end
end
