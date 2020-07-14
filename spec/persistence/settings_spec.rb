require 'spec_helper'

module Persistence
  describe Settings do
    let(:connection_id) { "nurelmremote" }
    let(:config) { { connection_id: connection_id } }
    subject {
      described_class.new(config)
    }
    let(:empty_s3_settings) { [] }
    let(:time) { (Time.now.utc - rand_mins).to_s }
    let(:rand_mins) { (rand(3) + 2) * 1.0 }
    let(:s3_settings) { [{"healthchecks"=>{"qbwc_last_contact_at"=>time}}] }

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

    describe 'healthcheck methods' do
      describe '#healthceck_is_failing?' do
        it 'returns false when there is no healthcheck setting' do
          allow(subject).to receive(:settings) { empty_s3_settings }
          expect(subject.healthceck_is_failing?).to be false
        end

        it 'returns false when the qbwc has updated the timestamp within the last 5 minutes' do
          allow(subject).to receive(:settings) { s3_settings }
          expect(subject.healthceck_is_failing?).to be false
        end

        describe 'when the qbwc has not updated the timestamp within the last 5 minutes' do
          let(:rand_mins) { (rand(30) + 2) * 1.0 }
          it 'returns true' do
            allow(subject).to receive(:settings) { s3_settings }
            expect(subject.healthceck_is_failing?).to be false
          end
        end

        describe 'when the qbwc was updated 30 minutes ago and the theshold is 45 minutes' do
          let(:rand_mins) { 30.0 }
          let(:config) { { connection_id: connection_id, health_check_threshold_in_minutes: 45 } }
          it 'returns false' do
            allow(subject).to receive(:settings) { s3_settings }
            expect(subject.healthceck_is_failing?).to be false
          end
        end

        describe 'when the qbwc was updated 45 minutes ago and the theshold is 30 minutes' do
          let(:rand_mins) { 45.0 }
          let(:config) { { connection_id: connection_id, health_check_threshold_in_minutes: 30 } }
          it 'returns true' do
            allow(subject).to receive(:settings) { s3_settings }
            expect(subject.healthceck_is_failing?).to be false
          end
        end
      end

      describe '#update_qbwc_last_contact_timestamp' do
        # Need to use VCR here to ensure we're updating correctly...
      end

      describe '#threshold' do
        it 'returns the default amount (5) when param is not set' do
          expect(subject.threshold).to eq(5)
        end

        describe 'when the parameter is set' do
          let(:config) { { connection_id: connection_id, health_check_threshold_in_minutes: rand_mins } }
          it 'returns the parameter amount' do
            expect(subject.threshold).to eq(rand_mins)
          end
        end
      end
    end

  end
end
