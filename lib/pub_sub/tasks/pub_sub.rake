namespace :pub_sub do
  desc 'Poll the queue for updates'
  task poll: [:environment, :subscribe] do
    worker_concurrency.times.map do |idx|
      sleep idx*10 # Allow things to load to avoid circular reference errors (loading classes ain't threadsafe)
      Thread.new { start_poll_thread }
    end.each(&:join)
  end

  desc 'Subscribe to the topics defined in the config'
  task subscribe: :environment do
    PubSub::Subscriber.subscribe
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
