require 'spec_helper'

module Persistence
  describe Settings do
    subject { described_class.new connection_id: '54591b3a5869632afc090000' }

    it "fetch existing config files" do
      VCR.use_cassette "settings/45435534253425" do
        configs = subject.fetch
      end
    end
  end
end
