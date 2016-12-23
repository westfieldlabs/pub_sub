require 'spec_helper'

RSpec.describe PubSub::Configuration do
  let(:logger) { double('Logger') }

  describe '#logger=' do
    it 'wraps into PubSub::Logger' do
      subject.logger = logger
      expect(subject.logger).to be_a PubSub::Logger
    end
  end

  describe '#subscribe_to' do
    it 'subscribes to all given services' do
      class Test1Update
      end
      class Test1Delete
      end
      class Test2Update
      end

      PubSub.configure do |config|
        config.subscribe_to 'test1', messages: ['test1_update', 'test1_delete']
        config.subscribe_to 'test2', messages: ['test2_update']
      end

      handlers =
        {
          'test1_update' => Test1Update,
          'test1_delete' => Test1Delete,
          'test2_update' => Test2Update
        }

      expect(PubSub.config.handlers).to eq(handlers)
    end
  end

end
