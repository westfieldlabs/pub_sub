namespace :pub_sub do
  namespace :cleanup do

    desc 'Removes abandoned topics and subscriptions'
    task :all, [:dry_run] => :environment do |t, args|
      args.with_defaults(dry_run: true)
      task('pub_sub:cleanup:subscriptions').invoke(args[:dry_run])
      puts
      task('pub_sub:cleanup:topics').invoke(args[:dry_run])
    end

    desc "Removes abandoned subscriptions (for this service only)"
    task :subscriptions, [:dry_run] => :environment do |t, args|
      args.with_defaults(dry_run: true)
      puts "Filtering by '#{PubSub.service_identifier}'"
      unrecognized_subs = []
      PubSub.config.regions.each do |region|
        client = Aws::SNS::Client.new(region: region)
        current_subs = PubSub::Subscriber.collect_all(client, :subscriptions)
        # Ignore unrelated subscriptions
        current_subs.select! do |subscription|
          short_endpoint_name = subscription.endpoint.split(/:/).last
          if PubSub.service_identifier == short_endpoint_name
            true
          else
            puts "#{subscription.subscription_arn} is unrelated".light_black
            false
          end
        end
        allowed_subs = PubSub.config.topics.values
        unrecognized_subs += current_subs.select do |subscription|
          short_topic_name = subscription.topic_arn.split(/:/).last
          is_allowed = allowed_subs.include? short_topic_name
          if is_allowed
            puts "#{subscription.subscription_arn} -> #{subscription.endpoint} is allowed".green
          else
            puts "#{subscription.subscription_arn} -> #{subscription.endpoint} is unrecognized".red
          end
          !is_allowed
        end
        if args[:dry_run] =~ /false/i
          unrecognized_subs.each do |subscription|
            sub = Aws::SNS::Subscription.new(subscription.subscription_arn, client: client)
            puts "Deleting subscription #{subscription.subscription_arn}".yellow
            sub.delete
          end
        end
      end

      unless args[:dry_run] =~ /false/i
        if unrecognized_subs.empty?
          puts "All current subscriptions are correct."
        else
          puts "\nThe following subscriptions are invalid (run 'rake pub_sub:cleanup:subscriptions[false]' to delete them for real):"
          unrecognized_subs.each do |subscription|
            puts subscription.subscription_arn
          end
        end
      end
    end


    desc "Removes abandoned topics (across ALL services)"
    task :topics, [:dry_run] => :environment do |t, args|
      args.with_defaults(dry_run: true)
      orphan_topics = []
      PubSub.config.regions.each do |region|
        client = Aws::SNS::Client.new(region: region)
        topics = PubSub::Subscriber.collect_all(client, :topics).map{|t| Aws::SNS::Topic.new(arn: t.topic_arn, client: client)}
        orphan_topics += topics.select do |t|
          puts "Inspecting #{t.arn}".light_black
          t.subscriptions.count == 0
        end
      end

      if args[:dry_run] =~ /false/i
        orphan_topics.each do |topic|
          puts "Deleting #{topic.arn}"
          topic.delete
        end
      else
        puts "The following topics are abandoned (run 'rake pub_sub:cleanup:topics[false]' to delete them for real):"
        orphan_topics.each do |topic|
          puts topic.arn
        end
      end
    end
  end
end
