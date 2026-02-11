class TodoSyncWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3, queue: 'default'

  def perform
    TodoSyncService.call
  rescue StandardError => e
    Rails.logger.error "[TodoSyncWorker] Fatal failure: #{e.message}"

    raise e
  end

  # Here we could define a strategy to send a message to Sentry or another similar service when the retries reach 5
  # In order to send a message when the record in the external API couldn't be deleted
end
