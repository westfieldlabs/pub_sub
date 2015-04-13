namespace :pub_sub do
  namespace :debug do
    desc 'List all PubSub debugging information.'
    task all: :environment do
      Rake::Task['pub_sub:debug:subscriptions'].invoke
      puts
      Rake::Task['pub_sub:debug:topics'].invoke
      puts
      Rake::Task['pub_sub:debug:queues'].invoke
    end

    desc 'List information about PubSub queues.'
    task queues: :environment do
      puts 'Queues: ', '----------'
      PubSub::Queue.new.list_queues.each do |queue|
        puts " - #{split_name(queue, '/')}"
      end
    end

    desc 'List information about the queue subscriptions.'
    task subscriptions: :environment do
      puts 'Subscriptions: ', '----------'
      subs = PubSub::Subscriber.new.list_subscriptions
      subs.sort_by(&:endpoint).each do |subscription|
        puts " - #{split_name(subscription.endpoint)} is listening to " \
             "#{split_name(subscription.topic_arn)}"
      end
    end

    desc 'List information about the topics.'
    task topics: :environment do
      puts 'Topics: ', '----------'
      PubSub::Publisher.new.list_topics.each do |topic|
        puts " - #{split_name(topic.topic_arn)}"
      end
    end
  end

  def split_name(string, delimiter = ':')
    string.to_s.split(delimiter).last
  end
end
