require 'rails_helper'

RSpec.describe "Api::TodoItems", type: :request do
  let!(:todo_list) { TodoList.create!(name: "Work", external_id: "ext_list_123") }
  let!(:todo_item) { TodoItem.create!(content: "Task to delete", todo_list: todo_list, external_id: "ext_item_456") }

  describe "DELETE /destroy" do
    it "deletes the local record and enqueues remote deletion" do
      expect(RemoteDeleteItemWorker).to receive(:perform_async).with("ext_list_123", "ext_item_456")

      expect {
        delete "/api/todolists/#{todo_list.id}/todo_items/#{todo_item.id}"
      }.to change(TodoItem, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    context "when external_ids are missing" do
      let!(:local_item) { TodoItem.create!(content: "Only local", todo_list: todo_list, external_id: nil) }

      it "deletes locally but does not enqueue remote deletion" do
        expect(RemoteDeleteItemWorker).not_to receive(:perform_async)

        expect { delete "/api/todolists/#{todo_list.id}/todo_items/#{local_item.id}" }.to change(TodoItem, :count).by(-1)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
