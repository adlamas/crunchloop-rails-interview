require 'rails_helper'
require 'webmock/rspec'

RSpec.describe TodoSyncService do
  let(:base_url) { "http://localhost:3000" }
  let(:endpoint) { "#{base_url}/todolists" }

  before do
    allow(ENV).to receive(:fetch).with('EXTERNAL_TODO_API_URL', anything).and_return(base_url)
  end

  describe '.call' do
    context 'when the external API response is successful' do
      let(:external_data) do
        [
          {
            "source_id" => "list_1",
            "name" => "Work",
            "items" => [
              { "source_id" => "item_1", "description" => "Task 1", "completed" => false }
            ]
          }
        ]
      end

      before do
        stub_request(:get, endpoint).to_return(
          status: 200,
          body: external_data.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'creates a TodoList and its items correctly' do
        expect { described_class.call }.to change(TodoList, :count).by(1)
                                      .and change(TodoItem, :count).by(1)
      end

      it 'is idempotent' do
        described_class.call # First sync
        expect { described_class.call }.not_to change(TodoList, :count)
      end

      it 'matches the database records with the external API data' do
        described_class.call

        # Fetch the created records
        synced_list = TodoList.find_by(external_id: "list_1")
        synced_item = TodoItem.find_by(external_id: "item_1")

        # Validate TodoList data
        expect(synced_list.name).to eq("Work")

        # Validate TodoItem data and its mapping (description -> content)
        expect(synced_item.content).to eq("Task 1")
        expect(synced_item.completed).to be false

        # Validate the relationship between them
        expect(synced_item.todo_list_id).to eq(synced_list.id)
      end
    end

    context 'when handling partial failures' do
      let(:mixed_data) do
        [
          { "source_id" => "valid_1", "name" => "Valid List", "items" => [] },
          { "source_id" => "invalid_2", "name" => nil },
          { "source_id" => "valid_3", "name" => "Another Valid", "items" => [] }
        ]
      end

      before do
        stub_request(:get, endpoint).to_return(
          status: 200, 
          body: mixed_data.to_json,
          headers: { 'Content-Type' => 'application/json' } 
        )
      end

      it 'continues syncing other lists if one fails' do
        expect(Rails.logger).to receive(:error).with(/Failed to sync list invalid_2/)
        expect { described_class.call }.to change(TodoList, :count).by(2)
      end
    end

    context 'when the API returns a high-level error' do
      before do
        stub_request(:get, endpoint).to_return(status: 500)
      end

      it 'raises a generic RuntimeError for Sidekiq to retry' do
        expect { 
          described_class.call 
        }.to raise_error(RuntimeError, /External API returned error: 500/)
      end
    end

    context 'when there is a connection failure' do
      before do
        stub_request(:get, endpoint).to_raise(SocketError.new("Failed to open TCP connection"))
      end

      it 're-raises the connection error' do
        expect(Rails.logger).to receive(:error).with(/Connection failed/)
        expect { described_class.call }.to raise_error(SocketError)
      end
    end
  end

  describe '#process_sync' do
    let(:service_instance) { described_class.new }
    let(:single_list_data) do
      {
        "source_id" => "new_remote_id",
        "name" => "Remote List",
        "items" => [
          { "source_id" => "new_item_id", "description" => "Remote Task", "completed" => true }
        ]
      }
    end

    it 'processes a single hash (from Worker) as successfully as an array' do
      expect { 
        service_instance.process_sync(single_list_data) 
      }.to change(TodoList, :count).by(1).and change(TodoItem, :count).by(1)

      synced_list = TodoList.find_by(external_id: "new_remote_id")
      expect(synced_list).to be_present
      expect(synced_list.name).to eq("Remote List")
      
      synced_item = TodoItem.find_by(external_id: "new_item_id")
      expect(synced_item.content).to eq("Remote Task")
      expect(synced_item.completed).to be true
    end

    it 'updates existing records instead of creating duplicates' do
      existing_list = TodoList.create!(name: "Old Name", external_id: "new_remote_id")
      
      expect {
        service_instance.process_sync(single_list_data)
      }.not_to change(TodoList, :count)
      
      expect(existing_list.reload.name).to eq("Remote List")
    end
  end
end
