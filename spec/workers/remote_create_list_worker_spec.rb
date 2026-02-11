require 'rails_helper'

RSpec.describe RemoteCreateListWorker, type: :worker do
  describe '#perform' do
    let(:todo_list) { TodoList.create!(name: "Local List") }
    let(:remote_response) do
      {
        "source_id" => "ext_L_123",
        "items" => [{ "source_id" => "ext_I_123", "description" => "Task" }]
      }
    end

    before do
      allow(ExternalTodoApiCreatorService).to receive(:create_list)
        .with(todo_list)
        .and_return(remote_response)

      allow_any_instance_of(TodoSyncService).to receive(:process_sync)
    end

    it 'calls the CreatorService and then the SyncService' do
      expect_any_instance_of(TodoSyncService).to receive(:process_sync).with(remote_response)

      described_class.new.perform(todo_list.id)
    end

    context 'error handling' do
      it 're-raises errors from the CreatorService to trigger Sidekiq retry' do
        allow(ExternalTodoApiCreatorService).to receive(:create_list).and_raise("API Down")

        expect {
          described_class.new.perform(todo_list.id)
        }.to raise_error(RuntimeError, "API Down")
      end
    end
  end
end
