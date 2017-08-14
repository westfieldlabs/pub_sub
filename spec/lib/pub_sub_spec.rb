require 'spec_helper'

RSpec.describe PubSub do
  describe '.sanitize_for_aws' do
    it 'returns the string sanitized for AWS' do
      expect(subject.sanitize_for_aws('test.westfield.com'))
        .to eq('test_westfield_com')
    end
  end
end
