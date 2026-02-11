class RemoteDeleteListWorker
  include Sidekiq::Worker
  
  sidekiq_options retry: 5, queue: 'sync'

  def perform(external_list_id)
    return if external_list_id.blank?

    ExternalTodoApiDestroyerService.delete_list(external_list_id)
  rescue StandardError => e
    Rails.logger.error "[RemoteDeleteList] Error deleting list #{external_list_id}: #{e.message}"
    raise e
  end

  # Here we could define a strategy to send a message to Sentry or another similar service when the retries reach 5
  # In order to send a message when the record in the external API couldn't be deleted
end
