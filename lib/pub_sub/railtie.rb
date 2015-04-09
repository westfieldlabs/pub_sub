module PubSub
  class Railtie < Rails::Railtie
    rake_tasks do
      Dir[File.join(File.dirname(__FILE__), 'tasks/*.rake')].each { |f| load f }
    end

    initializer 'pubsub_railtie.configure_rails_initialization' do
      PubSub.config.logger = Rails.logger

      # Amazon AWS configuration for SNS and SQS.
      ::AWS.config(
        access_key_id: PubSub.config.aws.access_key_id,
        secret_access_key: PubSub.config.aws.secret_access_key,
        region: PubSub.config.aws.region
      )
    end
  end
end
