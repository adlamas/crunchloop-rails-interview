class AddExternalIdToTodoListsAndItems < ActiveRecord::Migration[7.0]
  def change
    add_column :todo_lists, :external_id, :string
    add_index :todo_lists, :external_id, unique: true
    
    add_column :todo_items, :external_id, :string
    add_index :todo_items, :external_id, unique: true
  end
end
