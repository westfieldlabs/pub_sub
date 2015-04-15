module PubSub
  class Poller
    def initialize(queue_url, verbose = false)
      @queue_url = queue_url
      @verbose = verbose
    end

    def poll
      poller.poll(config) do |message|
        if @verbose
          PubSub.logger.info(
            "PubSub received: #{message.message_id} - #{message.body}"
          )
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
