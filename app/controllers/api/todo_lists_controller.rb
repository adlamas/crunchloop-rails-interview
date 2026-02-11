module Api
  class TodoListsController < ApplicationController
    # GET /api/todolists
    def index
      @todo_lists = TodoList.all

      respond_to :json
    end

    # POST /api/todolists
    def create
      @todo_list = TodoList.new(todo_list_params_mapping)

      if @todo_list.save
        if @todo_list.external_id.blank?
          RemoteCreateListWorker.perform_async(@todo_list.id)
        end

        render json: @todo_list, include: :todo_items, status: :created
      else
        render json: { errors: @todo_list.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      todo_list = TodoList.find(params[:id])
      ext_list_id = todo_list.external_id

      if todo_list.destroy
        if ext_list_id.present?
          RemoteDeleteListWorker.perform_async(ext_list_id)
        end

        render json: todo_list, status: :ok
      else
        render json: { errors: todo_list.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def todo_list_params_mapping
      raw_params = params.permit(:name, :source_id, items: [:description, :completed, :source_id])

      {
        name: raw_params[:name],
        external_id: raw_params[:source_id],
        todo_items_attributes: (raw_params[:items] || []).map do |item|
          {
            content: item[:description],
            completed: item[:completed] || false,
            external_id: item[:source_id]
          }
        end
      }
    end
  end
end
