class ExampleUpdate
  include PubSub::MessagePublisher
  include PubSub::MessageHandler

  def initialize(data)
    @data = data
  end

  def message_data
    {
      # Downcase the message to show data can be preprocessed
      name: @data[:name].downcase
    }
  end

end
