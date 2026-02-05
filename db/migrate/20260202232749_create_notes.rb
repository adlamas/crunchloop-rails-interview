class CreateNotes < ActiveRecord::Migration[7.0]
  def change
    create_table :notes do |t|
      t.string :content
      t.references :todo_list

      t.timestamps
    end
  end
end
