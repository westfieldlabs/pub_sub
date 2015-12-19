describe PubSub do

  before do
    PubSub.configure do |config|
      config.service 'test'
      config.subscribe_to_custom 'custom_identifier', messages: ['example'], topic: 'test'
    end
  end

 describe 'custom service identifier' do
    let(:object) { { id: 123, name: 'Example Message' } }
    let(:publisher) { ExampleUpdate.new(object) }
    let(:message) do
      JSON.dump(sender: "custom_identifier",
                type: 'example_update',
                data: {
                  name: 'example message'
                })
    end

    describe '#message_data' do
      it 'should return the correct json' do
        expect(publisher.message_data).to eql(name: 'example message')
      end
    end

  end

end
