namespace :pub_sub do
  desc 'Poll the queue for updates'
  task poll: [:environment, :subscribe] do
    worker_concurrency.times.map do
      sleep 5 # Allow things to load to avoid circular reference errors (loading classes ain't threadsafe)
      Thread.new { start_poll_thread }
    end.each(&:join)
  end

  desc 'Subscribe to the topics defined in the config'
  task subscribe: :environment do
    PubSub::Subscriber.subscribe
  end

  desc "Removes abandoned subscriptions (for this service only)"
  task :cleanup, [:dry_run] => :environment do |t, args|
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
      allowed_subs = PubSub.config.subscriptions.keys
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
          puts "Deleting #{subscription.subscription_arn}".yellow
          sub.delete
        end
      end
    end

    unless args[:dry_run] =~ /false/i
      if unrecognized_subs.empty?
        puts "All current subscriptions are correct."
      else
        puts "\nThe following subscriptions are invalid (run 'rake pub_sub:cleanup[false]' to delete them for real):"
        unrecognized_subs.each do |subscription|
          puts subscription.subscription_arn
        end
      end
    end
  end

  def start_poll_thread
    PubSub::Poller.new.poll
  rescue => e
    NewRelic::Agent.notice_error(e) if defined?(NewRelic)
    PubSub.logger.error("Unknown error polling subscriptions: #{e.inspect}")
    PubSub.logger.error(e.backtrace)
    retry
  end

  # How many threads to use for workers
  def worker_concurrency
    ENV.fetch('PUB_SUB_WORKER_CONCURRENCY', 2).to_i
  end
end
