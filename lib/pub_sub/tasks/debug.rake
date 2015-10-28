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
      message_count_attrs = %w(ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible ApproximateNumberOfMessagesDelayed)
      puts 'Queues: ', '----------'
      PubSub.config.regions.each do |region|
        sqs = Aws::SQS::Client.new(region: region)
        sqs.list_queues.queue_urls.each do |url|
          attributes = sqs.get_queue_attributes(
            queue_url: url,
            attribute_names: message_count_attrs
          )
          message_count = message_count_attrs.map{|x| attributes.attributes[x].to_i}.sum
          puts " - #{split_name(url, '/')} with #{message_count} messages in #{region}"
        end
      end
    end

    desc 'List information about the queue subscriptions.'
    task subscriptions: :environment do
      puts 'Subscriptions: ', '----------'
      puts "SERVICE\tSUBSCRIPTION\tPROTOCOL\tREGION"
      PubSub.config.regions.each do |region|
        client = Aws::SNS::Client.new(region: region)
        subs = collect_all(client, :subscriptions)
        subs.sort_by(&:endpoint).each do |subscription|
          puts [split_name(subscription.endpoint), split_name(subscription.topic_arn), subscription.protocol, region].join("\t")
        end
      end
    end

    desc 'List information about the topics.'
    task topics: :environment do
      puts 'Topics: ', '----------'
      PubSub.config.regions.each do |region|
        client = Aws::SNS::Client.new(region: region)
        topics = collect_all(client, :topics)
        topics.each do |topic|
          puts " - #{split_name(topic.topic_arn)} in #{region}"
        end
      end
    end
  end


  def split_name(string, delimiter = ':')
    string.to_s.split(delimiter).last
  end

  def collect_all(client, collection_type)
    elements = []
    next_token = ""
    loop do
      response = client.send("list_#{collection_type}".to_sym, next_token: next_token)
      elements.concat response.send(collection_type.to_sym)
      next_token = response.next_token
      break if next_token.to_s == ""
    end
    elements
  end

end
