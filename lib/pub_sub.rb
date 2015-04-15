require 'aws-sdk'
require 'json'
require 'pub_sub/version'
require 'pub_sub/errors'
require 'pub_sub/railtie' if defined?(Rails)

module PubSub
  autoload :Configuration,    'pub_sub/configuration'
  autoload :Poller,           'pub_sub/poller'
  autoload :Queue,            'pub_sub/queue'
  autoload :Subscriber,       'pub_sub/subscriber'
  autoload :Publisher,        'pub_sub/publisher'
  autoload :Message,          'pub_sub/message'
  autoload :MessageHandler,   'pub_sub/message_handler'
  autoload :MessagePublisher, 'pub_sub/message_publisher'

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

    def service_identifier(service_name = nil)
      service_name ||= PubSub.config.service_name
      "#{service_name}-service-#{env_suffix}"
    end

    # When in development or testing, we want to use our own personalized
    # queues. Using `development` would cause conflicts with other developers.
    def env_suffix
      if %w(development test).include?(rails_env)
        `whoami`.strip
      else
        rails_env
      end
    end

    def rails_env
      return Rails.env        if defined?(Rails)
      return ENV['RAILS_ENV'] if ENV['RAILS_ENV']
      return ENV['RACK_ENV']  if ENV['RACK_ENV']
      'development'
    end
  end
end
