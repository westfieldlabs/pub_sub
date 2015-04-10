module PubSub
  class PubSubError < StandardError
  end

  class ServiceUnknown < PubSubError
  end

  class MessageTypeUnknown < PubSubError
  end
end
