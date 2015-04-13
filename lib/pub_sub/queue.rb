module PubSub
  class Queue
    def self.poll
      new.poll
    end

    def poll
      timeout = PubSub.config.visibility_timeout
      queue.poll(visibility_timeout: timeout) do |message|
        Message.new(message.body).process
      end
    end

    def list_queues
      sqs.list_queues.queue_urls
    end

    private

    def sqs
      @sqs ||= Aws::SQS::Client.new
    end

    def queue
      @queue ||= sqs.create_queue(queue_name: queue_name)
    end

    def queue_name
      PubSub.service_identifier
    end
  end
end
