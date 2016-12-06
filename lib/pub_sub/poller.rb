require 'faraday'

module PubSub
  class Poller

    # Poll this service's queue until an error occurs.
    # It is advisable to wrap this method in a rescue-retry clause to poll indefinitely.
    def poll
      Breaker.execute do
        @queue = nil
        PubSub.logger.info "Listening to #{queue.queue_url}"
        poller.poll(config) do |message|
          PubSub.logger.log "PubSub [#{PubSub.config.service_name}] received message #{message.inspect}"
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

    def queue
      @queue ||= PubSub::Queue.new(region: PubSub.config.current_region)
    end

    def poller
      Aws::SQS::QueuePoller.new(queue.queue_url, client: queue.sqs)
    end

  end
end
