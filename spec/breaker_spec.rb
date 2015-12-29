require 'spec_helper'

describe PubSub::Breaker do

  before do
    %w(info debug error warn).each do |method|
      allow(PubSub.config).to receive_message_chain("logger.#{method}").and_return(anything())
    end
    PubSub.configure do |config|
      config.aws
    end
  end

  class TestError < StandardError; end
  let(:closed_breaker) { CB2::Breaker.new(strategy: "stub", allow: true) }
  let(:open_breaker) { CB2::Breaker.new(strategy: "stub", allow: false) }

  it "should be closed and executable" do
    i = 0
    PubSub::Breaker.execute do
      i = 1
    end
    expect(i).to eq(1)
  end

  it "should absorb failures when open" do
    allow(PubSub::Breaker).to receive(:get_breaker) { open_breaker }
    expect(PubSub::Breaker).to receive(:on_breaker_open) do
      raise TestError
    end
    expect do
      PubSub::Breaker.execute do
        raise NotImplementedError
      end
    end.to raise_error(TestError)
  end

  it "should expose failures when open" do
    allow(PubSub::Breaker).to receive(:get_breaker) { closed_breaker }
    expect(PubSub::Breaker).not_to receive(:on_breaker_open)
    expect do
      PubSub::Breaker.execute do
        raise NotImplementedError
      end
    end.to raise_error(NotImplementedError)
  end

  it "should work in the multi-threaded environment" do
    limit = 1000
    threads = limit.times.map do |i|
      Thread.new do
        PubSub::Breaker.execute do
          Thread.current[:result] = i
        end
      end
    end
    threads.map(&:join)
    expected = limit.times.inject(0){|r,i| r += i}
    actual = threads.map{|t| t[:result]}.inject(0){|r,i| r += i}
    expect(actual).to eq(expected)
  end

end
