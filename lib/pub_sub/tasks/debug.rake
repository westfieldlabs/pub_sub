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
      sqs = Aws::SQS::Client.new
      sqs.list_queues.queue_urls.each do |url|
        message_count = sqs.get_queue_attributes(
          queue_url: url,
          attribute_names: ['ApproximateNumberOfMessages']
        ).attributes['ApproximateNumberOfMessages']
        puts " - #{split_name(url, '/')} with #{message_count} messages"
      end
    end

    desc 'List information about the queue subscriptions.'
    task subscriptions: :environment do
      puts 'Subscriptions: ', '----------'
      subs = Aws::SNS::Client.new.list_subscriptions.subscriptions
      subs.sort_by(&:endpoint).each do |subscription|
        puts " - #{split_name(subscription.endpoint)} is listening to " \
             "#{split_name(subscription.topic_arn)}"
      end
    end

    desc 'List information about the topics.'
    task topics: :environment do
      puts 'Topics: ', '----------'
      Aws::SNS::Client.new.list_topics.topics.each do |topic|
        puts " - #{split_name(topic.topic_arn)}"
      end
    end
  end

  def split_name(string, delimiter = ':')
    string.to_s.split(delimiter).last
  end
end
