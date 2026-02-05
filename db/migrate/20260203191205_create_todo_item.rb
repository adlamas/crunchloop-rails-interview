class CreateTodoItem < ActiveRecord::Migration[7.0]
  def change
    create_table :todo_items do |t|
      t.string :content
      t.boolean :completed, default: false
      t.references :todo_list, null: false

      t.timestamps
    end
  end
end
