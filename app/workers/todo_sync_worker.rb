class TodoSyncWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3, queue: 'default'

  def perform
    TodoSyncService.call
  rescue StandardError => e
    Rails.logger.error "[TodoSyncWorker] Fatal failure: #{e.message}"

    raise e
  end
end
