module Api
  class TodoItemsController < ApplicationController
    def index
      todo_list = TodoList.find(todo_list_id)

      render json: todo_list.todo_items
    end

    def create
      todo_list = TodoList.find(todo_list_id)
      todo_item = todo_list.todo_items.new(todo_items_params)

      if todo_item.save
        render json: todo_item, status: :created
      else
        render json: { errors: todo_item.errors }, status: :unprocessable_entity
      end
    end

    def destroy
      todo_item = TodoItem.find(params[:id])

      ext_list_id = todo_item.todo_list.external_id
      ext_item_id = todo_item.external_id

      if todo_item.destroy
        if ext_list_id.present? && ext_item_id.present?
          RemoteDeleteItemWorker.perform_async(ext_list_id, ext_item_id)
        end

        render json: todo_item, status: :ok
      else
        render json: { errors: todo_item.errors }, status: :unprocessable_entity
      end
    end

    def update
      todo_item = TodoItem.find(params[:id])

      if todo_item.update(todo_items_params)
        ext_list_id = todo_item.todo_list.external_id
        ext_item_id = todo_item.external_id

        if ext_list_id.present? && ext_item_id.present?
          RemoteUpdateItemWorker.perform_async(todo_item.id)
        end

        render json: todo_item, status: :ok
      else
        render json: { errors: todo_item.errors }, status: :unprocessable_entity
      end
    end

    def complete
      todo_item = TodoItem.find(params[:todo_item_id])

      if todo_item.complete!
        render json: todo_item, status: :ok
      else
        render json: { errors: "todo item not completed!" }, status: :unprocessable_entity
      end
    end

    private

    def todo_list_id
      params[:todo_list_id]
    end

    def todo_items_params
      params.require(:todo_item).permit(:content)
    end
  end
end
