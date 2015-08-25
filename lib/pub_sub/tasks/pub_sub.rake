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
    # loop do
    #   begin
    #     queue.poll visibility_timeout: 60 * 60, idle_timeout: rand(30...120), &block
    #     increment_queue_counter
    #   rescue => e
    #     NewRelic::Agent.notice_error(e)
    #     puts e
    #   end
    # end
    loop do
      begin
        puts "STARTED"
        poller.poll
        puts "IDLED"
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
    end
  end

  def poller
    pollers[0]
  end

  def pollers
    @pollers ||= PubSub::REGIONS.map do |region|
      queue_url = PubSub::Queue.new(region: region).queue_url
      PubSub::Poller.new(queue_url, verbose?, region: region)
    end
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
