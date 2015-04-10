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

    private

    def sqs
      @sqs ||= AWS::SQS.new
    end

    def queue
      @queue ||= sqs.queues.create(queue_name)
    end

    def queue_name
      PubSub.service_identifier
    end
  end
end
