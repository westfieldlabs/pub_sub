module PubSub

  class Configuration
    attr_accessor :service_name,
                  :subscriptions,
                  :topics,
                  :visibility_timeout,
                  :logger,
                  :regions

    SUPPORTED_REGIONS = %w(us-east-1 us-west-1 eu-west-1 ap-southeast-1)

    def initialize
      @subscriptions = {}
      @topics = {}
      # How long to wait before retrying a failed message
      @visibility_timeout = 1200 # seconds, 20 minutes
    end

    def service(service_name)
      @service_name = service_name.to_s
    end

    def current_region
      regions.first
    end

    # Subscribe to a specific sender for specific message types.
    # The identifier generated from {service_name} is used for both
    # the sender and the topic.
    def subscribe_to(service_name, messages: [])
      service_identifier = PubSub.service_identifier(service_name)
      subscribe_to_custom(service_identifier, messages: messages)
    end

    # A fully custom alternative to `subscribe_to`.
    # You can specify the sender, messages, and topic - all independently.
    # If topic is not specified, the value for {service_identifier} will be used.
    def subscribe_to_custom(service_identifier, messages: [], topic: nil)
      topic ||= service_identifier
      @subscriptions[service_identifier] = messages
      @topics[service_identifier] = topic
    end

    # Configure AWS credentials and region. Omit (nil) any of the parameters to use environment defaults
    def aws(key: ENV['AWS_ACCESS_KEY_ID'],
        secret: ENV['AWS_SECRET_ACCESS_KEY'],
        regions: ['us-east-1'])
      raise(ArgumentError, "Invalid region(s): #{regions-ALLOWED_REGIONS}") if (regions-SUPPORTED_REGIONS).present?
      raise(ArgumentError, "Only 1 region at a time is currently supported") if regions.size > 1
      @regions = regions
      ::Aws.config.update(credentials: Aws::Credentials.new(key, secret))
    end

  end
end
