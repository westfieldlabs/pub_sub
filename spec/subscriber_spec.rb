require 'spec_helper'
require 'thread'

describe PubSub::Subscriber do

  let(:semaphore) { Mutex.new }

  before do
    %w(info debug error warn).each do |method|
      allow(PubSub.config).to receive_message_chain("logger.#{method}").and_return(anything())
    end
    PubSub.configure do |config|
      config.aws
    end
    # Replace the underlying Redlock which does not work in test environment
    allow(described_class).to receive(:critical_section) do |&block|
      semaphore.synchronize do
        block.call
      end
    end
  end

  describe '#subscribe' do
    it 'should be thread-safe' do
      limit = 10
      counter = 0
      allow_any_instance_of(described_class).to receive(:subscribe) do
        # introduce race conditions on purpose - PubSub::Subscriber.subscribe should protect against that
        old_value = counter
        sleep rand
        counter = old_value + 1
      end
      limit.times.map do |i|
        Thread.new do
          PubSub::Subscriber.subscribe
        end
      end.each(&:join)
      expect(counter).to eq(limit)
    end
  end
end
