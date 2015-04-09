require 'aws-sdk-v1'
require 'pub_sub/version'
require 'pub_sub/railtie' if defined?(Rails)

module PubSub
  autoload :Configuration,  'pub_sub/configuration'
  autoload :Queue,          'pub_sub/queue'
  autoload :Subscriber,     'pub_sub/subscriber'
  autoload :Publisher,      'pub_sub/publisher'
  autoload :Message,        'pub_sub/message'

  autoload :EventHandler,   'pub_sub/event_handler'
  autoload :EventPublisher, 'pub_sub/event_publisher'

  class << self
    attr_accessor :config

    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config)
    end

    def logger
      PubSub.config.logger
    end

    # When in development or testing, we want to use our own personalized
    # queues. Using `development` would cause conflicts with other developers.
    def env_suffix
      if %w(development test).include?(Rails.env)
        `whoami`.strip
      else
        Rails.env
      end
    end
  end
end
