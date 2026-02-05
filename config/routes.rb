Rails.application.routes.draw do
  namespace :api do
    resources :todo_lists, only: %i[index create], path: :todolists do
      collection do
        get 'coleccion'
      end

      member do
        get 'miembro'
      end

      resources :todo_items, only: %i[index create destroy update] do
        put 'complete'
      end

      resources :notes, only: %i[index create], module: :todo_lists
    end
  end

  #resources :todo_lists, only: %i[index new], path: :todolists
end
