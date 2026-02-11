
class RemoteUpdateItemWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3, queue: 'sync'

  def perform(item_id)
    item = TodoItem.find_by(id: item_id)
    return unless item && item.external_id.present?

    ExternalTodoApiUpdaterService.update_item(
      item.todo_list.external_id,
      item.external_id,
      { content: item.content, completed: item.completed }
    )
  end
end
