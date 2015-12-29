require 'redlock'
require 'thread'

module PubSub
  class Subscriber
    SUBSCRIBE_TIMEOUT = 30000 # ms
    @@semaphore = Mutex.new

    def self.subscribe
      critical_section do
        new.send(:subscribe)
      end
    end

    private

    def self.critical_section(&block)
      @@semaphore.synchronize do
        @@distributed_lock ||= Redlock::Client.new ["redis://#{Redis.current.client.location}"]
      end
      @@distributed_lock.lock!(:pubsub_subscribe, SUBSCRIBE_TIMEOUT) do
        yield
      end
    end

    def subscribe
      PubSub.config.regions.each do |region|
        topics = PubSub.config.subscriptions.keys.map do |service_identifier|
          topic = PubSub.config.topics[service_identifier]
          subscribe_to_service(service_identifier, topic, region)
        end
        set_queue_policy(topics.map(&:arn), region)
      end
    end

    def subscribe_to_service(sender, topic_id, region)
      topic = Aws::SNS::Topic.new(sns(region).create_topic(name: topic_id).topic_arn, region: region)
      topic.subscribe(endpoint: queue_arn(region), protocol: 'sqs')
      PubSub.logger.info "Subscribed #{queue_arn(region)} to #{topic.arn} for sender #{sender}"
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

    # Collects all :topics or :subscriptions for a given SNS client
    def self.collect_all(client, collection_type)
      elements = []
      next_token = ""
      loop do
        response = client.send("list_#{collection_type}".to_sym, next_token: next_token)
        elements.concat response.send(collection_type.to_sym)
        next_token = response.next_token
        break if next_token.to_s == ""
      end
      elements
    end

  end
end
