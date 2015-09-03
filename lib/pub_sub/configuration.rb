module PubSub
  class Configuration
    attr_accessor :service_name,
                  :subscriptions,
                  :visibility_timeout,
                  :logger

    def initialize
      @subscriptions = {}
      @visibility_timeout = 3600 # 1 hour
    end

    def service(service_name)
      @service_name = service_name.to_s
    end

    def subscribe_to(service_name, messages: [], service_identifier: nil)
      service_identifier ||= PubSub.service_identifier(service_name)
      @subscriptions[service_identifier] = messages
    end

    # Configure AWS credentials and region. Omit (nil) any of the parameters to use environment defaults
    def aws(
        key: ENV['AWS_ACCESS_KEY_ID'],
        secret: ENV['AWS_SECRET_ACCESS_KEY'],
        region: (ENV['AWS_REGION'] || 'us-east-1')) # TODO: Remove the hardcoded region
      ::Aws.config.update(
        credentials: Aws::Credentials.new(key, secret),
        region: region
      )
    end

  end
end
