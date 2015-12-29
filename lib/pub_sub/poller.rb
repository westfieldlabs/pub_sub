require 'faraday'

module PubSub
  class Poller

    # Poll for messages across all regions
    def poll
      Breaker.execute do
        poller.poll(config) do |message|
          PubSub.logger.debug "PubSub [#{PubSub.config.service_name}] received: #{message}"
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
      q = PubSub::Queue.new(region: PubSub.config.current_region)
      Aws::SQS::QueuePoller.new(q.queue_url, client: q.sqs)
    end

  end
end
