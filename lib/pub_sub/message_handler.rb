module PubSub
  module MessageHandler
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def process
      error = 'A message handler must implement a `process` method.'
      fail NotImplementedError, error
    end
  end
end
