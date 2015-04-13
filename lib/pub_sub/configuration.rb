module PubSub
  class Configuration
    attr_accessor :service_name,
                  :subscriptions,
                  :visibility_timeout,
                  :logger,
                  :aws

    def initialize
      @subscriptions = {}
      @aws = {}
      @visibility_timeout = 1.hour
    end

    def service(service_name)
      @service_name = service_name.to_s
    end

    def subscribe_to(service_name, messages: [])
      service_identifier = PubSub.service_identifier(service_name)
      @subscriptions[service_identifier] = messages
    end

    def aws(key: nil, secret: nil, region: 'us-east-1')
      @aws['access_key_id'] = key
      @aws['secret_access_key'] = secret
      @aws['region'] = region
    end
  end
end
