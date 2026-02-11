class RemoteCreateListWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3, queue: 'sync'

  def perform(todo_list_id)
    todo_list = TodoList.find_by(id: todo_list_id)
    return unless todo_list && todo_list.external_id.nil?

    remote_data = ExternalTodoApiCreatorService.create_list(todo_list)

    TodoSyncService.new.process_sync(remote_data)

    Rails.logger.info "[RemoteCreateListWorker] Successfully propagated and synced List #{todo_list_id}"
  rescue StandardError => e
    Rails.logger.error "[ExternalAPI] POST CreateList failed - for TodoList ID: #{todo_list_id}"
    Rails.logger.error "[RemoteCreateListWorker] Critical error: #{e.message}"
    raise e
  end

  # Here we could define a strategy to send a message to Sentry or another similar service when the retries reach 5
  # In order to send a message when the record in the external API couldn't be deleted
end
