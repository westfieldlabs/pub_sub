module PubSub
  class Queue

    def initialize(region: nil)
      raise(ArgumentError, "Region is invalid or missing: #{region}") unless Configuration::SUPPORTED_REGIONS.include?(region)
      @region = region
    end

    def queue_url
      Breaker.execute do
        sqs.create_queue(queue_name: queue_name).queue_url
      end
    end

    def queue_arn
      Breaker.execute do
        sqs.get_queue_attributes(
          queue_url: queue_url, attribute_names: ["QueueArn"]
        ).attributes["QueueArn"]
      end
    end

    def queue_attributes(attribute_names)
      sqs.get_queue_attributes(queue_url: queue_url, attribute_names: attribute_names).values.first
    end

    def message_count(include_invisible: true, include_delayed: true)
      attributes = ['ApproximateNumberOfMessages']
      attributes << 'ApproximateNumberOfMessagesNotVisible' if include_invisible
      attributes << 'ApproximateNumberOfMessagesDelayed' if include_delayed
      queue_attributes(attributes).values.map(&:to_i).sum
    end

    def sqs
      Aws::SQS::Client.new(region: @region)
    end

    private

    def queue_name
      PubSub.service_identifier
    end
  end
end
