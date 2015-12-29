require 'spec_helper'

describe PubSub::Poller do

  let(:message) do
    double(message_id: '123', attributes: {a: 1}, body: JSON.dump({
      sender: "test-service-#{PubSub.env_suffix}",
      type: 'example_update',
      data: {
        name: 'example message'
      }
    }))
  end
  
  class ExpectedExit < StandardError; end

  before do
    %w(info debug error warn).each do |method|
      allow(PubSub).to receive_message_chain("logger.#{method}").and_return(anything())
    end
    allow_any_instance_of(PubSub::Queue).to receive(:queue_url) { nil }
    PubSub.configure do |config|
      config.service 'test'
      config.subscribe_to 'test', messages: ['example_update']
      config.aws
    end
    expect_any_instance_of(Aws::SQS::QueuePoller).to receive(:poll) do |config, &block|
      catch :skip_delete do
        block.call message
      end
      raise(ExpectedExit, "Exit after :skip_delete") # exit out of circuit breaker
    end
  end


  describe '#poll' do
    it 'should break on a generic error' do
      expect(ExampleUpdate).to receive(:process) do
        raise StandardError.new("This is a generic error test")
      end
      expect{ described_class.new.poll }.to raise_error(StandardError)
    end

    it 'should not break on a timeout' do
      expect(ExampleUpdate).to receive(:process) do
        raise Faraday::TimeoutError.new("Timeout test")
      end
      expect{ described_class.new.poll }.to raise_error(ExpectedExit)
    end
  end
end
