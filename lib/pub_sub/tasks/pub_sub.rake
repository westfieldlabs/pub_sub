namespace :pub_sub do
  desc 'Poll the queue for updates'
  task poll: [:environment, :subscribe] do
    worker_concurrency.times.map do |idx|
      # Give each thread some time to load to avoid circular reference errors (class-loading is not threadsafe)
      # [FIXME] ^ (written by a previous developer) likely refers to Breaker, though I still am not convinced there is a race condition.
      sleep idx*5
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
