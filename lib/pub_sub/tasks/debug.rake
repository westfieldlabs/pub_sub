namespace :pub_sub do
  namespace :debug do
    desc 'List all PubSub debugging information.'
    task :all, [:filter,:region] => :environment do |t, args|
      args.with_defaults(filter: "", region: "")
      task('pub_sub:debug:topics').invoke(args[:filter], args[:region])
      puts
      task('pub_sub:debug:queues').invoke(args[:filter], args[:region])
      puts
      task('pub_sub:debug:subscriptions').invoke(args[:filter], args[:region])
    end

    desc 'List information about the topics.'
    task :topics, [:filter,:region] => :environment do |t, args|
      args.with_defaults(filter: nil, region: nil)
      puts 'Topics: ', '----------'
      PubSub.config.regions.each do |region|
        next if args[:region].present? && region != args[:region]
        client = Aws::SNS::Client.new(region: region)
        topics = PubSub::Subscriber.collect_all(client, :topics)
        topics.select!{|t| t.topic_arn =~ Regexp.new(args[:filter])} if args[:filter].present?
        topics.each do |topic|
          puts " - #{topic.topic_arn}"
          topic = Aws::SNS::Topic.new(topic.topic_arn, client: client)
          topic.subscriptions.each do |subscription|
            puts "\t -> #{subscription.arn}"
          end
        end
      end
    end

    desc 'List information about PubSub queues.'
    task :queues, [:filter,:region] => :environment do |t, args|
      args.with_defaults(filter: nil, region: nil)
      message_count_attrs = %w(ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible ApproximateNumberOfMessagesDelayed)
      puts 'Queues: ', '----------'
      PubSub.config.regions.each do |region|
        next if args[:region].present? && region != args[:region]
        sqs = Aws::SQS::Client.new(region: region)
        sqs.list_queues.queue_urls.each do |url|
          next unless args[:filter].blank? || url =~ Regexp.new(args[:filter])
          attributes = sqs.get_queue_attributes(
            queue_url: url,
            attribute_names: message_count_attrs
          )
          message_count = message_count_attrs.map{|x| attributes.attributes[x].to_i}.sum
          puts " - #{message_count} messages in #{url}"
        end
      end
    end

    desc 'List information about the queue subscriptions.'
    task :subscriptions, [:filter,:region] => :environment do |t, args|
      args.with_defaults(filter: nil, region: nil)
      puts 'Subscriptions: ', '----------'
      PubSub.config.regions.each do |region|
        next if args[:region].present? && region != args[:region]
        client = Aws::SNS::Client.new(region: region)
        subs = PubSub::Subscriber.collect_all(client, :subscriptions)
        subs.select!{|s| s.endpoint =~ Regexp.new(args[:filter] || s.topic_arn =~ Regexp.new(args[:filter])} if args[:filter].present?
        subs.sort_by(&:endpoint).each do |subscription|
          puts "[#{split_name(subscription.subscription_arn)}]\t#{subscription.endpoint} is listening to #{subscription.topic_arn}"
        end
      end
    end
  end


  def split_name(string, delimiter = ':')
    string.to_s.split(delimiter).last
  end

end
