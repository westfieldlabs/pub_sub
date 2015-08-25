module PubSub

  class Breaker

    THREAD_LOCAL_IDENTIFIER = :pub_sub_region

    class << self

      def current_breaker
        all_breakers[current_breaker_idx]
      end

      def current_region
        all_regions[current_breaker_idx]
      end

      def use_next_breaker
        Thread.current[THREAD_LOCAL_IDENTIFIER] += 1
        Thread.current[THREAD_LOCAL_IDENTIFIER] = Thread.current[THREAD_LOCAL_IDENTIFIER] % all_breakers.count
      end

      private

      def current_breaker_idx
        Thread.current[THREAD_LOCAL_IDENTIFIER] ||= 0
      end

      def all_breakers
        @breakers ||= all_regions.map do |region|
          CB2::Breaker.new(
          service: "aws-#{region}",
          duration: 60,
          threshold: 50,
          reenable_after: 60,
          redis: Redis.current)
        end
      end

      def all_regions
        PubSub.config.regions
      end

    end

  end

end
