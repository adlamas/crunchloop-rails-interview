require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe TodoSyncWorker, type: :worker do
  describe '#perform' do
    it 'calls the TodoSyncService' do
      expect(TodoSyncService).to receive(:call)

      described_class.new.perform
    end

    context 'when the service raises an error' do
      before do
        allow(TodoSyncService).to receive(:call).and_raise(StandardError, "API Down")
      end

      it 'logs the fatal error when Sidekiq fails' do
        expect(Rails.logger).to receive(:error).with(/Fatal failure: API Down/)

        expect {
          described_class.new.perform
        }.to raise_error(StandardError, "API Down")
      end
    end
  end
end
