class ExternalTodoApiCreatorService
  include HTTParty
  base_uri ENV.fetch('EXTERNAL_TODO_API_URL', 'http://localhost:3000')

  def self.create_list(todo_list)
    endpoint = "/todolists"

    Rails.logger.info "[ExternalAPI] POST CreateList started for TodoList ID: #{todo_list.id}"

    body = {
      name: todo_list.name,
      items: todo_list.todo_items.map do |item|
        {
          description: item.content,
          completed: item.completed || false
        }
      end
    }.to_json

    response = post(endpoint, 
                    body: body, 
                    headers: { 'Content-Type' => 'application/json' }, 
                    timeout: 15)

    if response.success?
      Rails.logger.info "[ExternalAPI] POST CreateList success for TodoList ID: #{todo_list.id}"
      return response.parsed_response
    else
      Rails.logger.error "[ExternalAPI] POST CreateList failed - Status: #{response.code}, Body: #{response.body}"
      raise "Failed to create remote list: #{response.code}"
    end
  end
end
