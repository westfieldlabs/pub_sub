module PubSub
  class Railtie < Rails::Railtie
    rake_tasks do
      Dir[File.join(File.dirname(__FILE__), 'tasks/*.rake')].each { |f| load f }
    end

    initializer 'pub_sub.initialize' do
      PubSub.config.logger = Rails.logger



      require 'pub_sub/railties/active_record'
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.send :include, PubSub::Railties::ActiveRecord
      end
    end
  end
end
