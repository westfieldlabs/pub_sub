require "spec_helper"

RSpec.describe PubSub::Publisher do
  let(:message) {{ message_payload: "data goes here", type: "parking_exit_notification" }.to_json}

  subject { described_class.publish(message) }

  describe "#publish" do
    it "publishes a message synchronously by default" do
      expect(described_class)
        .to receive(:publish_synchronously).with(message, anything)
      described_class.publish(message)
    end

    context "when async: true is passed as a parameter" do
      it "publishes a message asynchronously" do
        expect(described_class)
          .to receive(:publish_asynchronously).with(message, anything)
        described_class.publish(message, async: true)
      end
    end
  end

  describe "#publish_synchronously" do
    let(:logger) { double.as_null_object }
    let(:sns) { double(:sn) }
    let(:topic_arn) { "topic:arn:goes:here" }
    let(:pub_sub_config) do
      double(:pub_sub_config, service_name: "some-service", current_region: "us-east",
                              logger: logger)
    end
    before do
      allow(PubSub).to receive(:config).and_return(pub_sub_config)
      allow(Aws::SNS::Client).to receive(:new).and_return(sns)
      allow(PubSub::Breaker).to receive(:execute).and_yield
      allow(sns).to receive(:create_topic).and_return(double(:topic, topic_arn: topic_arn))
      allow(sns).to receive(:publish).and_return(double(message_id: "some-message-id"))
    end

    it "publishes a message" do
      expect(sns).to receive(:publish).and_return(double(message_id: "some-message-id"))
      described_class.publish_synchronously(message, "some topic")
    end

    it "looks up the topic_arn for the given topic" do
      expect(sns).to receive(:create_topic).with(name: "some topic")
      described_class.publish_synchronously(message, "some topic")
    end

    it "publishes a message with the given topic_arn" do
      expect(sns).to receive(:publish).with(hash_including(topic_arn: "topic:arn:goes:here"))
      described_class.publish_synchronously(message, "some topic")
    end

    it "logs the message details" do
      expected_logging_details = %([PubSub] published message: {) +
                                 %("service_name":"some-service",) +
                                 %("message_type":"parking_exit_notification",) +
                                 %("message_id":"some-message-id",) +
                                 %("topic_arn":"topic:arn:goes:here"})
      expect(logger).to receive(:log).with(expected_logging_details)
      described_class.publish_synchronously(message, "some topic")
    end

    context "when the message cannot be parsed" do
      let(:message) { "some string" }
      it "logs an unknown message type in the message details" do
        expected_logging_details = %([PubSub] published message: {) +
                                   %("service_name":"some-service",) +
                                   %("message_type":"unknown",) +
                                   %("message_id":"some-message-id",) +
                                   %("topic_arn":"topic:arn:goes:here"})
        expect(logger).to receive(:log).with(expected_logging_details)
        described_class.publish_synchronously(message, "some topic")
      end
    end
  end
end
