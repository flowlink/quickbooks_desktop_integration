require 'spec_helper'

module Persistence
  describe Settings do
    let(:connection_id) { "nurelmremote" }
    subject {
      described_class.new({ connection_id: connection_id })
    }

    describe 'reader methods' do
      it '#base_name' do
        expect(subject.base_name).to eq "#{connection_id}/settings"
      end
    end

    describe '#setup' do
      it 'returns nil when no extra flows to generate' do
        expect(subject.setup).to be nil
      end
    end

    describe '#settings' do
      it 'returns an array with prefix get_' do
        expect(subject.settings('get_')).to be_instance_of Array
      end
    end

  end
end
