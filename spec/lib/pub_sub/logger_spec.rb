require 'spec_helper'

RSpec.describe PubSub::Logger do
  let(:logger) { double("Logger") }
  subject { described_class.new(logger) }

  describe "#log" do
    it "logs the using received log_level" do
      expect(logger).to receive(:warn).with("test")

      subject.log("test", :warn)
    end

    it "logs the using configured PubSub log_level" do
      PubSub.config.log_level = :info
      expect(logger).to receive(:info).with("test")

      subject.log("test")
    end
  end
end
