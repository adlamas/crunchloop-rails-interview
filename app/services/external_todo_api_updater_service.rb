class ExternalTodoApiUpdaterService
  include HTTParty

  base_uri ENV.fetch('EXTERNAL_TODO_API_URL', 'http://localhost:3000')

  # Updates a TodoItem in the external API
  def self.update_item(external_list_id, external_item_id, params)
    endpoint = "/todolists/#{external_list_id}/todoitems/#{external_item_id}"
    
    # Mapping local attributes to external API expectations
    body = {
      description: params[:content],
      completed: params[:completed]
    }.to_json

    response = patch(endpoint, 
                     body: body, 
                     headers: { 'Content-Type' => 'application/json' }, 
                     timeout: 10)

    unless response.success?
      Rails.logger.error "[ExternalAPI] PATCH UpdateItem failed - Status: #{response.code}, Response: #{response.body}"
      raise "Failed to update remote item: #{response.code}"
    end

    response
  end

end
