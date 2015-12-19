require 'spec_helper'
describe PubSub::Breaker do

  before do
    %w(info debug error warn).each do |method|
      allow(PubSub.config).to receive_message_chain("logger.#{method}").and_return(anything())
    end
    @breakers = 4.times.map do |index|
      double("breaker#{index}")
    end
    PubSub.configure do |config|
      config.aws
    end
  end

  describe 'current breaker' do

    it "should return the breaker at the correct index" do
      expect(PubSub::Breaker).to receive(:all_breakers).and_return @breakers
      expect(PubSub::Breaker.current_breaker).to eq(@breakers[0])
    end

  end

  describe 'current region' do

    it "be default, should start with us-east-1" do
      expect(PubSub::Breaker.current_region).to eq('us-east-1')
    end
  end

  describe 'use next breaker' do

    it "should advance both regions and breakers" do
      expect(PubSub::Breaker).to receive(:all_breakers).twice.and_return @breakers
      PubSub::Breaker.use_next_breaker
      expect(PubSub::Breaker.current_region).to eq('us-west-1')
      expect(PubSub::Breaker).to receive(:all_breakers).and_return @breakers
      expect(PubSub::Breaker.current_breaker).to eq(@breakers[1])
    end

    it "should wrap around regions and breakers" do
      allow(PubSub::Breaker).to receive(:all_breakers).and_return @breakers
      PubSub::Breaker.use_next_breaker
      expect(PubSub::Breaker.current_region).to eq('eu-west-1')
      expect(PubSub::Breaker.current_breaker).to eq(@breakers[2])
      PubSub::Breaker.use_next_breaker
      expect(PubSub::Breaker.current_breaker).to eq(@breakers[3])
      PubSub::Breaker.use_next_breaker
      expect(PubSub::Breaker.current_breaker).to eq(@breakers[0])
    end

    it 'should be thread safe' do
      allow(PubSub::Breaker).to receive(:all_breakers).and_return @breakers
      # This should surface timing problems
      10.times do
        Thread.new do
          100.times do
            PubSub::Breaker.use_next_breaker
          end
        end
      end
      Thread.new do
        expect(PubSub::Breaker.current_breaker).to eq(@breakers[0])
        PubSub::Breaker.use_next_breaker
        expect(PubSub::Breaker.current_breaker).to eq(@breakers[1])
      end
      Thread.new do
        expect(PubSub::Breaker.current_breaker).to eq(@breakers[0])
        PubSub::Breaker.use_next_breaker
        expect(PubSub::Breaker.current_breaker).to eq(@breakers[1])
      end
      expect(PubSub::Breaker.current_breaker).to eq(@breakers[0])
    end

  end

end
