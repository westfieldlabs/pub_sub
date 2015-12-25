require 'faraday'

module PubSub
  class Poller

    # Poll for messages across all regions
    def poll
      loop do
        Breaker.run do
          poller.poll(config) do |message|
            PubSub.logger.debug "PubSub [#{PubSub.config.service_name}, #{queue_url}] received: #{message.body}"
            begin
              Message.new(message.body).process
            rescue Faraday::TimeoutError => e
              PubSub.logger.warn "#{e.message}. Message #{message.inspect} will be retried later"
              throw :skip_delete
            end
          end
        end
        Breaker.use_next_breaker # TODO: What is this here for? Doesn't Breaker.run already loop?
      end
    end

    private

    def config
      {
        visibility_timeout: PubSub.config.visibility_timeout,
        idle_timeout: PubSub.config.idle_timeout,
      }
    end
    
    def queue_url
      PubSub::Queue.new.queue_url
    end

    def poller
      Aws::SQS::QueuePoller.new(queue_url, client: client)
    end

    def client
      Aws::SQS::Client.new(region: Breaker.current_region)
    end

  end
end
