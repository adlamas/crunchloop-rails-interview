class TodoList < ApplicationRecord
  has_many :todo_items, dependent: :destroy
  
  accepts_nested_attributes_for :todo_items
  
  validates :name, presence: true
end
