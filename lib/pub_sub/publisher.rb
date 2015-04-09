module PubSub
  class Publisher
    include Singleton

    attr_accessor :sns, :topic

    def self.topic
      instance.topic
    end

    def sns
      @sns ||= AWS::SNS.new
    end

    def topic
      @topic ||= sns.topics.create(topic_name)
    end

    private

    def topic_name
      "#{PubSub.config.service_name}-#{PubSub.env_suffix}"
    end
  end
end
