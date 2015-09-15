namespace :pub_sub do
  desc 'Poll the queue for updates'
  task poll: :environment do
    worker_concurrency.times.map do
      sleep 5 # Allow things to load to avoid circular reference errors
      Thread.new { start_poll_thread }
    end.each(&:join)
  end

  desc 'Subscribe to the topics defined in the config'
  task subscribe: :environment do
    PubSub::Subscriber.subscribe
  end

  def start_poll_thread
    PubSub::Poller.new(verbose?).poll
  rescue PubSub::ServiceUnknown => e
    # Skip messages when we know we're not meant to process them
    error = "Not processing message: #{e.inspect}"
    PubSub.logger.error(error)
  rescue => e
    NewRelic::Agent.notice_error(e) if defined?(NewRelic)
    PubSub.logger.error("Unknown error polling subscriptions: #{e.inspect}")
    PubSub.logger.error(e.backtrace)
    retry
  end

  def verbose?
    ENV['VERBOSE'] == 'true'
  end

  def worker_concurrency
    ENV.fetch('PUB_SUB_WORKER_CONCURRENCY', 2).to_i
  end
end
