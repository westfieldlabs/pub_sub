require 'spec_helper'

describe PubSub do
  before do
    PubSub.configure do |config|
      config.service 'test'
      config.subscribe_to 'test', messages: ['example']
    end
  end

  describe 'message handler' do
  end

  describe 'message publisher' do
    let(:object) { { id: 123, name: 'Example Message' } }
    let(:publisher) { ExampleUpdate.new(object) }
    let(:message) do
      JSON.dump(sender: "test-service-#{PubSub.env_suffix}",
                type: 'example_update',
                data: {
                  name: 'example message'
                })
    end

    describe 'message data' do
      it 'should return the correct json' do
        expect(publisher.message_data).to eql(name: 'example message')
      end
    end

    describe 'publish' do
      it 'should publish syncronously by default' do
        expect(PubSub::Publisher).to(
          receive(:publish).with(message, async: false)
        )
        publisher.publish
      end

      it 'should publish syncronously' do
        expect(PubSub::Publisher).to(
          receive(:publish).with(message, async: false)
        )
        publisher.publish(async: false)
      end

      it 'should publish asyncronously' do
        expect(PubSub::Publisher).to(
          receive(:publish).with(message, async: true)
        )
        publisher.publish(async: true)
      end
    end
  end
end
