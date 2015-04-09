module PubSub
  class Configuration
    attr_accessor :service_name,
                  :subscriptions,
                  :visibility_timeout,
                  :logger,
                  :aws

    def initialize
      @subscriptions = Set.new
      @visibility_timeout = 1.hour
      @aws = Hashie::Mash.new(
        access_key_id: nil,
        secret_access_key: nil,
        region: 'us-east-1'     # Default region
      )
    end

    def service(service_name)
      @service_name = "#{service_name}-service"
    end

    def subscribe_to!(*service_names)
      Array.wrap(service_names).each do |service_name|
        @subscriptions.add(service_name)
      end
    end
  end
end
