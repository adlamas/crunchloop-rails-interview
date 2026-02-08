Rails.application.routes.draw do
  namespace :api do
    resources :todo_lists, only: %i[index create], path: :todolists do
      resources :todo_items, only: %i[index create destroy update] do
        put 'complete'
      end

      resources :notes, only: %i[index create], module: :todo_lists
    end
  end

  resources :todo_lists, only: %i[index new], path: :todolists
end
