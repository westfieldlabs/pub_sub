module PubSub
  module MessageHandler

    def self.process(_data)
      error = 'A message handler must implement a `process` method.'
      fail NotImplementedError, error
    end
  end
end
