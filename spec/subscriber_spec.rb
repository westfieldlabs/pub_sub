require 'spec_helper'

# cannot use PubSub::Subscriber here because it would be evaluated before
# our overrides for Redlock below are processed
describe "PubSub::Subscriber" do

  let(:semaphore) { Mutex.new }

  before do
    %w(info debug error warn log).each do |method|
      allow(PubSub.config).to receive_message_chain("logger.#{method}").and_return(anything())
    end
    PubSub.configure do |config|
      config.service 'test'
      config.subscribe_to 'test', messages: ["example_update"]
      config.aws
    end
  end

  describe '#subscribe' do
    it 'should work' do
      PubSub::Subscriber.subscribe
      ExampleUpdate.new(name: 'some name').publish
      expect(ExampleUpdate).to receive(:process) do
        raise NotImplementedError
      end
      expect do
        PubSub::Poller.new.poll
      end.to raise_error(NotImplementedError)
    end
  end

end
