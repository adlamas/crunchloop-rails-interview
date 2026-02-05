module Api
  module TodoLists
    class NotesController < ApplicationController
      def create
        list = TodoList.find(todo_list_id)
        note = list.notes.build(items_params)

        render json: { note: note }, status: :created
      end

      private

      def todo_list_id
        params.require('todo_list_id')
      end

      def items_params
        params.require('note').permit('content')
      end
    end
  end
end
