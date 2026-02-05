class TodoItem < ApplicationRecord

  def complete!
    self.update!(completed: true)
  end

  belongs_to :todo_list, optional: false

end
