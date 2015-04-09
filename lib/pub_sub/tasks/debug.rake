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
      sqs.queues.each do |queue|
        puts " - #{queue_name(queue.arn)} with approx. " \
             "#{queue.approximate_number_of_messages} messages"
      end
    end

    desc 'List information about the queue subscriptions.'
    task subscriptions: :environment do
      puts 'Subscriptions: ', '----------'
      sns.subscriptions.sort_by(&:endpoint).each do |subscription|
        puts " - #{queue_name(subscription.endpoint)} is listening to " \
             "#{subscription.topic.name}"
      end
    end

    desc 'List information about the topics.'
    task topics: :environment do
      puts 'Topics: ', '----------'
      sns.topics.each do |topic|
        puts " - #{topic.name}"
      end
    end
  end

  def sqs
    @sqs ||= AWS::SQS.new
  end

  def sns
    @sns ||= AWS::SNS.new
  end

  def queue_name(string)
    string.split(':').last
  end
end
