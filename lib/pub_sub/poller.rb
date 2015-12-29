require 'faraday'

module PubSub
  class Poller

    # Poll for messages across all regions
    def poll
      Breaker.execute do
        poller.poll(config) do |message|
          PubSub.logger.debug "PubSub [#{PubSub.config.service_name}] received message #{message.inspect}"
          begin
            Message.new(message.body).process
          rescue Faraday::TimeoutError => e
            PubSub.report_error e, "Message #{message.inspect} will be retried later"
            throw :skip_delete
          end
        end
      end
    end

    private

    def config
      {
        visibility_timeout: PubSub.config.visibility_timeout,
      }
    end

    def poller
      @queue = PubSub::Queue.new(region: PubSub.config.current_region)
      Aws::SQS::QueuePoller.new(@queue.queue_url, client: @queue.sqs)
    end

  end
end
