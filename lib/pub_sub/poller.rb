module PubSub
  class Poller
    def initialize(queue_url, verbose = false, region: )
      @queue_url = queue_url
      @verbose = verbose
      @region = region
    end

    def poll
      poller.poll(idle_timeout: 60) do |message|
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
      Aws::SQS::QueuePoller.new(@queue_url, client: Aws::SQS::Client.new(region: @region))
    end

  end
end
