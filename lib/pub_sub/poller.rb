module PubSub
  class Poller
    def initialize(verbose = false)
      @verbose = verbose
    end

    def poll
      loop do
        Breaker.current_breaker.run do
          poller.poll(config) do |message|
            if @verbose
              PubSub.logger.info(
                "PubSub received: #{message.message_id} - #{message.body}"
              )
            end
            Message.new(message.body).process
          end
        end
        Breaker.use_next_breaker
      end
    rescue CB2::BreakerOpen
      Breaker.use_next_breaker
      sleep 1
      retry
    end

    private

    def config
      {
        visibility_timeout: PubSub.config.visibility_timeout,
        idle_timeout: PubSub.config.idle_timeout,
      }
    end

    def poller
      Aws::SQS::QueuePoller.new(PubSub::Queue.new.queue_url, client: client)
    end

    def client
      Aws::SQS::Client.new(region: Breaker.current_region)
    end

  end
end
