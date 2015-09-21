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
  end


  describe 'messages are filtered out' do
    let(:message) {
      {
        "uri" => "https://example.com/entity/11355",
        "id" => 11355
      }
    }
    class EntityUpdate
    end

    context 'quietly' do
      let(:payload) { raw_sns_message['body'] }

      it 'on unknown senders' do
        allow(PubSub.config.subscriptions).to receive(:[]).with(
          'entity-service-prod'
        ).and_return(nil)
        allow(PubSub.config).to receive_message_chain("logger.error").and_return(anything())
        # first, make sure the validator throws an exception
        expect{subject.validate_message!}.to raise_error(PubSub::ServiceUnknown)
        # then, make sure `process` does not
        subject.process
      end

      it 'on unknown types' do
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


  describe 'messages are NOT filtered out' do
    let(:message) {
      {
        "uri" => "https://example.com/entity/11355",
        "id" => 11355
      }
    }
    class EntityUpdate
    end

    context 'on' do
      let(:payload) { raw_sns_message['body'] }

      it 'other errors' do
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
