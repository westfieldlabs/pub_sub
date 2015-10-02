require 'spec_helper'

RSpec.describe PubSub::Message do
  let(:raw_sns_message) {
    {
      'message_id' => 'msg-uuid',
      'body' => '{
        "Type" : "Notification",
        "MessageId" : "different-msg-uuid",
        "TopicArn" : "arn:aws:sns:region:aws_account_id:entity-service-prod",
        "Message" : "{\"sender\":\"entity-service-prod\",\"type\":\"entity_update\",\"data\":{\"uri\":\"https://example.com/entity/11355\",\"id\":11355}}",
        "Timestamp" : "2015-06-19T22:11:55.760Z",
        "SignatureVersion" : "1",
        "Signature" : "signature==",
        "SigningCertURL" : "https://sns.us-east-1.amazonaws.com/entity-xyz.pem",
        "UnsubscribeURL" : "https://sns.us-east-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:region:aws_account_id:entity-service-prod:uuid"
      }'
    }
  }
  subject { described_class.new(payload) }

  before do
    %w(info debug error).each do |method|
      allow(PubSub.config).to receive_message_chain("logger.#{method}").and_return(anything())
    end
  end

  describe '#process' do
    let(:message) {
      {
        "uri" => "https://example.com/entity/11355",
        "id" => 11355
      }
    }
    class EntityUpdate
    end
    context 'message is valid' do
      before do
        allow(PubSub.config.subscriptions).to receive(:[]).with(
          'entity-service-prod'
        ).and_return(['entity_update'])
      end

      context 'subscriptions with RawMessageDelivery=false' do
        let(:payload) { raw_sns_message['body'] }
        it 'processes the message' do
          expect(EntityUpdate).to receive(:process).with(message)
          subject.process
        end
      end

      context 'subscriptions with RawMessageDelivery=true' do
        let(:payload) { "{\"sender\":\"entity-service-prod\",\"type\":\"entity_update\",\"data\":{\"uri\":\"https://example.com/entity/11355\",\"id\":11355}}" }
        it 'processes the message' do
          expect(EntityUpdate).to receive(:process).with(message)
          subject.process
        end
      end
    end

    context "message is not valid" do

      context 'with unknown sender' do
        let(:payload) { raw_sns_message['body'] }

        it 'catches and logs error' do
          allow(PubSub.config.subscriptions).to receive(:[]).with(
            'entity-service-prod'
          ).and_return(nil)
          allow(PubSub.config).to receive_message_chain("logger.error").and_return(anything())
          # first, make sure the validator throws an exception
          expect{subject.validate_message!}.to raise_error(PubSub::ServiceUnknown)
          # then, make sure `process` does not
          subject.process
        end
      end

      context 'with unknown message type' do
        let(:payload) { raw_sns_message['body'] }

        it 'catches and logs error' do
          allow(PubSub.config.subscriptions).to receive(:[]).with(
            'entity-service-prod'
          ).and_return(['unknown_type'])
          allow(PubSub.config).to receive_message_chain("logger.error").and_return(anything())
          # first, make sure the validator throws an exception
          expect{subject.validate_message!}.to raise_error(PubSub::MessageTypeUnknown)
          # then, make sure `process` does not
          subject.process
        end
      end
    end

    context 'with some other problem' do
      let(:payload) { raw_sns_message['body'] }

      it 'raises errors' do
        allow(PubSub.config.subscriptions).to receive(:[]).with(
          'entity-service-prod'
        ).and_return(nil)
        allow(PubSub.config).to receive_message_chain("logger.error").and_return(anything())
        expect(subject).to receive(:validate_message!).and_throw(:test_error)
        expect{subject.process}.to raise_error(UncaughtThrowError)
      end
    end
  end

end
