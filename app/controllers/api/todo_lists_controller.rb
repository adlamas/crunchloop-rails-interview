module Api
  class TodoListsController < ApplicationController
    # GET /api/todolists
    def index
      @todo_lists = TodoList.all

      respond_to :json
    end

    def create
      render json: { ruta: 'Entro en el metodo CREATE' }
    end

    def coleccion
      render json: { ruta: 'Entro en el metodo coleccion' }
    end
  end
end
