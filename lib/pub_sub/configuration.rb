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

    def subscribe_to(service_name, messages: [])
      service_identifier = PubSub.service_identifier(service_name)
      @subscriptions[service_identifier] = messages
    end

    def aws(key: nil, secret: nil, region: 'us-east-1')
      ::Aws.config.update(
        credentials: Aws::Credentials.new(key, secret),
        region: region
      )
    end
  end
end
