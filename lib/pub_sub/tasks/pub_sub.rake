namespace :pub_sub do
  desc 'Poll the queue for updates'
  task poll: [:environment, :subscribe] do
    # avoid race conditions if multiple threads load classes
    Rails.application.eager_load!

    worker_concurrency.times.map do |idx|
      Thread.new do
        start_poll_thread
      end
    end.each(&:join)
  end

  desc 'Subscribe to the topics defined in the config'
  task subscribe: :environment do
    PubSub::Subscriber.subscribe
  end

  def start_poll_thread
    PubSub::Poller.new.poll
  rescue => e
    # Unexpected error during poll. Report and retry.
    PubSub.report_error(e)
    retry
  end

  # How many threads to use for workers
  def worker_concurrency
    ENV.fetch('PUB_SUB_WORKER_CONCURRENCY', 4).to_i
  end
end
