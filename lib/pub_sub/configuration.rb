module PubSub

  class Configuration
    attr_accessor :service_name,
                  :subscriptions,
                  :visibility_timeout,
                  :logger,
                  :regions

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
    def aws(key: ENV['AWS_ACCESS_KEY_ID'],
        secret: ENV['AWS_SECRET_ACCESS_KEY'],
        regions: (%w(us-east-1 us-west-1 eu-west-1 ap-southeast-1))
        )
      @regions = regions
      ::Aws.config.update(
        credentials: Aws::Credentials.new(key, secret)
      )
    end

  end
end
