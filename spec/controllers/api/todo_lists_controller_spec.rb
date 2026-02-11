require 'rails_helper'

describe Api::TodoListsController do
  render_views

  describe 'GET index' do
    let!(:todo_list) { TodoList.create(name: 'Setup RoR project') }

    context 'when format is HTML' do
      it 'raises a routing error' do

        expect {
          get :index
        }.to raise_error(ActionController::RoutingError, 'Not supported format')
      end
    end

    context 'when format is JSON' do
      it 'returns a success code' do
        get :index, format: :json

        expect(response.status).to eq(200)
      end

      it 'includes todo list records' do
        get :index, format: :json

        todo_lists = JSON.parse(response.body)

        aggregate_failures 'includes the id and name' do
          expect(todo_lists.count).to eq(1)
          expect(todo_lists[0].keys).to match_array(['id', 'name'])
          expect(todo_lists[0]['id']).to eq(todo_list.id)
          expect(todo_lists[0]['name']).to eq(todo_list.name)
        end
      end
    end
  end

  describe 'POST create' do
    let(:valid_params) do
      {
        name: 'New External List',
        source_id: 'ext_123',
        items: [
          { description: 'First task', completed: false, source_id: 'item_1' },
          { description: 'Second task', completed: true, source_id: 'item_2' }
        ]
      }
    end

    context 'with valid external API params' do
      it 'creates a new TodoList' do
        expect {
          post :create, params: valid_params, format: :json
        }.to change(TodoList, :count).by(1)
      end

      it 'creates the associated TodoItems' do
        expect {
          post :create, params: valid_params, format: :json
        }.to change(TodoItem, :count).by(2)
      end

      it 'returns a 201 created status' do
        post :create, params: valid_params, format: :json
        expect(response.status).to eq(201)
      end

      it 'correctly maps external fields to internal schema' do
        post :create, params: valid_params, format: :json

        json_response = JSON.parse(response.body)
        new_list = TodoList.find(json_response['id'])

        aggregate_failures 'field mapping' do
          expect(new_list.name).to eq('New External List')
          expect(new_list.external_id).to eq('ext_123')

          first_item = new_list.todo_items.find_by(external_id: 'item_1')
          expect(first_item.content).to eq('First task') # description -> content
          expect(first_item.completed).to be false
        end
      end
    end

    context 'with invalid params' do
      it 'returns 422 unprocessable entity when name is missing' do
        post :create, params: { source_id: 'fail_1' }, format: :json
        expect(response.status).to eq(422)
      end
    end

    context 'when name is missing' do
      let(:invalid_params) do
        {
          source_id: 'ext_999',
          items: [
            { description: 'Orphan item', source_id: 'item_999' }
          ]
        }
      end

      it 'does not create a new TodoList' do
        expect {
          post :create, params: invalid_params, format: :json
        }.not_to change(TodoList, :count)
      end

      it 'does not create any TodoItems' do
        expect {
          post :create, params: invalid_params, format: :json
        }.not_to change(TodoItem, :count)
      end

      it 'returns 422 unprocessable entity' do
        post :create, params: invalid_params, format: :json
        expect(response.status).to eq(422)
      end

      it 'returns detailed error messages' do
        post :create, params: invalid_params, format: :json
        json_response = JSON.parse(response.body)

        expect(json_response['errors']).to include("Name can't be blank")
      end
    end
  end

  describe "DELETE destroy" do
    let!(:todo_list) { TodoList.create!(name: "Project X", external_id: "ext_L_999") }

    let!(:item_1) { TodoItem.create!(content: "Task 1", todo_list: todo_list) }
    let!(:item_2) { TodoItem.create!(content: "Task 2", todo_list: todo_list) }

    it "deletes the list and its associated items locally and enqueues remote deletion" do
      expect(RemoteDeleteListWorker).to receive(:perform_async).with("ext_L_999")

      expect {
        delete :destroy, params: { id: todo_list.id }, format: :json
      }.to change(TodoList, :count).by(-1)
       .and change(TodoItem, :count).by(-2)

      expect(response.status).to eq(200)
    end

    it "returns 404 if the list does not exist" do
      expect {
        delete :destroy, params: { id: 99999 }, format: :json
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "when list has no external_id" do
      let!(:local_list) { TodoList.create!(name: "Local Only") }
      let!(:local_item) { TodoItem.create!(content: "Local Task", todo_list: local_list) }

      it "deletes locally (including items) but does NOT enqueue remote deletion" do
        expect(RemoteDeleteListWorker).not_to receive(:perform_async)

        expect {
          delete :destroy, params: { id: local_list.id }, format: :json
        }.to change(TodoList, :count).by(-1)
         .and change(TodoItem, :count).by(-1)

        expect(response.status).to eq(200)
      end
    end
  end
end
