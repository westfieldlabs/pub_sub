module PubSub
  module MessageHandler

    # This should be overridden by the including class
    def self.process(_data)
      error = 'A message handler must implement a `process` method.'
      fail NotImplementedError, error
    end
  end
end
