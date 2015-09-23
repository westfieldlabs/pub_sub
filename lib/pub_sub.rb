require 'aws-sdk'
require 'active_support/all'
require 'json'
require 'cb2'
require 'redis'
require 'pub_sub/version'
require 'pub_sub/errors'
require 'pub_sub/railtie' if defined?(Rails)

module PubSub
  autoload :Configuration,    'pub_sub/configuration'
  autoload :Poller,           'pub_sub/poller'
  autoload :Queue,            'pub_sub/queue'
  autoload :Subscriber,       'pub_sub/subscriber'
  autoload :Breaker,          'pub_sub/breaker'
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
        # FIXME - this should probably be overridable with an ENV variable
        `whoami`.strip
      else
        rails_env
      end
    end

    # FIXME - this should probably be renamed to just `env` or similar
    def rails_env
      return Rails.env if defined?(Rails)
      ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
    end

    def stub_responses!
      Aws.config[:stub_responses] = true
    end
  end
end
