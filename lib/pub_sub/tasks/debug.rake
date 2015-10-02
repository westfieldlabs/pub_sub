namespace :pub_sub do
  namespace :debug do
    desc 'List all PubSub debugging information.'
    task all: :environment do
      Rake::Task['pub_sub:debug:topics'].invoke
      puts
      Rake::Task['pub_sub:debug:queues'].invoke
      puts
      Rake::Task['pub_sub:debug:subscriptions'].invoke
    end

    desc 'List information about PubSub queues.'
    task queues: :environment do
      puts 'Queues: ', '----------'
      PubSub.config.regions.each do |region|
        sqs = Aws::SQS::Client.new(region: region)
        sqs.list_queues.queue_urls.each do |url|
          message_count = sqs.get_queue_attributes(
            queue_url: url,
            attribute_names: ['ApproximateNumberOfMessages']
          ).attributes['ApproximateNumberOfMessages']
          puts " - #{split_name(url, '/')} with #{message_count} messages in #{region}"
        end
      end
    end

    desc 'List information about the queue subscriptions.'
    task subscriptions: :environment do
      puts 'Subscriptions: ', '----------'
      PubSub.config.regions.each do |region|
        subs = Aws::SNS::Client.new(region: region).list_subscriptions.subscriptions
        subs.sort_by(&:endpoint).each do |subscription|
          # TODO - it would be useful to know what kind of an endpoint this is - webhook, SQS, email, etc
          puts " - #{split_name(subscription.endpoint)} is listening to " \
               "#{split_name(subscription.topic_arn)} in #{region}"
        end
      end
    end

    desc 'List information about the topics.'
    task topics: :environment do
      puts 'Topics: ', '----------'
      PubSub.config.regions.each do |region|
        Aws::SNS::Client.new(region: region).list_topics.topics.each do |topic|
          puts " - #{split_name(topic.topic_arn)} in #{region}"
        end
      end
    end
  end

  def split_name(string, delimiter = ':')
    string.to_s.split(delimiter).last
  end
end
