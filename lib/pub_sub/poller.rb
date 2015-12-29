require 'faraday'

module PubSub
  class Poller

    # Poll for messages across all regions
    def poll
      Breaker.execute do
        poller.poll(config) do |message|
          PubSub.logger.debug "PubSub [#{PubSub.config.service_name}] received from #{@queue.queue_url}: #{message}"
          begin
            Message.new(message.body).process
          rescue Faraday::TimeoutError => e
            PubSub.logger.warn "#{e.message}. Message #{message.inspect} will be retried later"
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
