class TodoSyncService
  include HTTParty

  def self.call
    new.call
  end

  def call
    base_url = ENV.fetch('EXTERNAL_TODO_API_URL', 'http://localhost:3000')
    endpoint = "#{base_url}/todolists"

    Rails.logger.info "[SyncService] Initiating synchronization from: #{endpoint}"

    response = self.class.get(endpoint, timeout: 60) # If there are a LOT of lists

    if response.success?
      process_sync(response.parsed_response)
    else
      # High-level error for Sidekiq to catch and trigger retries
      error_message = "[SyncService] External API returned error: #{response.code}"
      Rails.logger.error error_message
      raise error_message
    end
  rescue SocketError, Errno::ECONNREFUSED => e
    # Connectivity issues are logged and re-raised for the worker retry mechanism
    Rails.logger.error "[SyncService] Connection failed: #{e.message}"
    raise e
  end

  def process_sync(external_lists)
    external_lists = [external_lists] if external_lists.is_a?(Hash)

    external_lists.each do |list_data|
      # Wrapping each list in its own block to handle partial failures.
      # If one list fails, the loop continues with the next one.
      begin
        TodoList.transaction do
          sync_single_list(list_data)
        end
      rescue StandardError => e
        # Partial failure: log the specific list error and skip to the next
        Rails.logger.error "[SyncService] Failed to sync list #{list_data['source_id']}: #{e.message}"

        # Here we can send a message to a tool like Sentry to communicate that we had an error
        next
      end
    end
  end

  private

  def sync_single_list(list_data)
    # Upsert logic for the parent TodoList
    todo_list = TodoList.find_or_initialize_by(external_id: list_data['source_id'])
    todo_list.update!(name: list_data['name'])

    sync_items_efficiently(todo_list, list_data['items'] || [])
  end

  def sync_items_efficiently(todo_list, items_data)
    return if items_data.empty?

    # Processing in batches to optimize memory and DB performance for large datasets
    items_data.each_slice(5000) do |batch|
      timestamp = Time.current

      items_attributes = batch.map do |item_data|
        {
          todo_list_id: todo_list.id,
          external_id:  item_data['source_id'],
          content:      item_data['description'],
          completed:    item_data['completed'] || false,
          created_at:   timestamp,
          updated_at:   timestamp
        }
      end

      # Atomic database operation: Insert new items or update existing ones based on external_id
      TodoItem.upsert_all(items_attributes, unique_by: :external_id)
    end
  end
end
