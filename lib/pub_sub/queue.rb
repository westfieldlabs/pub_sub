module PubSub
  class Queue

    def queue_url
      Breaker.current_breaker.run do
        sqs.create_queue(queue_name: queue_name).queue_url
      end
    rescue CB2::BreakerOpen
      Breaker.use_next_breaker
      sleep 1
      retry
    end

    def queue_arn
      Breaker.current_breaker.run do
        sqs.get_queue_attributes(
          queue_url: queue_url, attribute_names: ["QueueArn"]
        ).attributes["QueueArn"]
      end
    rescue CB2::BreakerOpen
      Breaker.use_next_breaker
      sleep 1
      retry
    end

    private

    def sqs
      Aws::SQS::Client.new(region: Breaker.current_region)
    end

    def queue_name
      PubSub.service_identifier
    end
  end
end
