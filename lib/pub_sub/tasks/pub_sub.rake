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
    PubSub::Subscriber.subscribe!
  end

  def start_poll_thread
    PubSub::Queue.poll!
  rescue => e
    PubSub.logger.error("Error polling subscriptions: #{e.inspect}")
    PubSub.logger.error(e.backtrace)
    retry
  end

  def worker_concurrency
    ENV.fetch('WORKER_CONCURRENCY', 2).to_i
  end
end
