require 'spec_helper'

RSpec.describe PubSub::Publisher do
  class Example
  end

  before do
    %w(info debug error warn log).each do |method|
      allow(PubSub).to receive_message_chain("logger.#{method}").and_return(anything())
    end
    PubSub.configure do |config|
      config.service 'test'
      config.subscribe_to 'test', messages: ['example']
    end
  end

  let(:object) { { id: 123, name: 'Example Message' } }
  let(:publisher) { ExampleUpdate.new(object) }
  let(:message) do
    JSON.dump(sender: "test-service-#{PubSub.env_suffix}",
              origin: `whoami`.strip,
              type: 'example_update',
              data: {
                name: 'example message'
              })
  end

  describe '#message_data' do
    it 'should return the correct json' do
      expect(publisher.message_data).to eql(name: 'example message')
    end
  end

  describe '#publish' do
    it 'should publish syncronously by default' do
      expect(PubSub::Publisher).to receive(:publish).with(message, async: false, topic: PubSub.service_identifier)
      publisher.publish
    end

    it 'should publish syncronously' do
      expect(PubSub::Publisher).to receive(:publish).with(message, async: false, topic: PubSub.service_identifier)
      publisher.publish(async: false)
    end

    it 'should publish asyncronously' do
      expect(PubSub::Publisher).to receive(:publish).with(message, async: true, topic: PubSub.service_identifier)
      publisher.publish(async: true)
    end
  end

  describe '#topic_name' do
    class CustomUpdate
      include PubSub::MessagePublisher
      def message_data
        {}
      end
    end
    let(:publish_result) { double(message_id: nil) }

    it 'can be overridden' do
      PubSub.configure do |config|
        config.service 'publisher-test'
        config.subscribe_to 'something', messages: ['example_update']
        config.aws
      end
      expect_any_instance_of(Aws::SNS::Client).to receive(:publish) { publish_result }
      expect(PubSub::Publisher).to receive(:topic_arn).with(:test)
      CustomUpdate.new.publish(async: false, topic: :test)
    end
  end
end
