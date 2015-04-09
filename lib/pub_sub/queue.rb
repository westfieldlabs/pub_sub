module PubSub
  class Queue
    attr_accessor :sqs, :queue

    def self.poll!
      new.poll!
    end

    def sqs
      @sqs ||= AWS::SQS.new
    end

    def queue
      @queue ||= sqs.queues.create(queue_name)
    end

    def poll!
      timeout = PubSub.config.visibility_timeout
      queue.poll(visibility_timeout: timeout) do |message|
        Message.new(message.body).process
      end
    end

    private

    def queue_name
      "#{PubSub.config.service_name}-#{PubSub.env_suffix}"
    end
  end
end
