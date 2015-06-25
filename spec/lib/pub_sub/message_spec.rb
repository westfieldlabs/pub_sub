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
end
