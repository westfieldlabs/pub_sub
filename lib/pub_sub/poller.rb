module PubSub
  class Poller
    def initialize(queue_url, verbose = false)
      @queue_url = queue_url
      @verbose = verbose
    end

    def poll
      poller.poll(config) do |message, stats|
        if @verbose
          PubSub.logger.info("Requests: #{stats.request_count}")
          PubSub.logger.info("Messages: #{stats.received_message_count}")
          PubSub.logger.info("Last-timestamp: #{stats.last_message_received_at}")
        end
        Message.new(message.body).process
      end
    end

    private

    def poller
      Aws::SQS::QueuePoller.new(@queue_url)
    end

    def config
      {
        visibility_timeout: PubSub.config.visibility_timeout
      }
    end
  end
end
