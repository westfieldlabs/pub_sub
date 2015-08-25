module PubSub
  class Poller
    def initialize(queue_url, verbose = false)
      @verbose = verbose
    end

    def poll
      loop do
        Breaker.current_breaker.run do
          poller.poll(idle_timeout: 60) do |message|
            if @verbose
              PubSub.logger.info(
                "PubSub received: #{message.message_id} - #{message.body}"
              )
            end
            Message.new(message.body).process
          end
        end
        puts "IDLED"
        Breaker.use_next_breaker
      end
    rescue CB2::BreakerOpen
      puts "BROKEN"
      Breaker.use_next_breaker
      sleep 1
      retry
    end

    private

    def poller
      puts PubSub::Queue.new.queue_url
      puts client
      Aws::SQS::QueuePoller.new(PubSub::Queue.new.queue_url, client: client)
    end

    def client
      Aws::SQS::Client.new(region: Breaker.current_region)
    end

  end
end
