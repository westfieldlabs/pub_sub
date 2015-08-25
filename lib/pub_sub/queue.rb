module PubSub
  class Queue

    def initialize
      @sqs ||= Aws::SQS::Client.new(region: region)
    end

    def queue_url
      @queue_url ||= begin
        sqs.create_queue(queue_name: queue_name).queue_url
      end
    end

    def queue_arn
      @queue_arn ||= sqs.get_queue_attributes(
        queue_url: queue_url, attribute_names: ["QueueArn"]
      ).attributes["QueueArn"]
    end

    private

    def sqs
      @sqs
    end

    def queue_name
      PubSub.service_identifier
    end
  end
end
