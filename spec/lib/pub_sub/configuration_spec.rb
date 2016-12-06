require 'spec_helper'

RSpec.describe PubSub::Configuration do
  let(:logger) { double("Logger") }

  describe "#logger=" do
    it "wraps into PubSub::Logger" do
      subject.logger = logger
      expect(subject.logger).to be_a PubSub::Logger
    end
  end
end
