class ExternalTodoApiDestroyerService
  include HTTParty

  base_uri ENV.fetch('EXTERNAL_TODO_API_URL', 'http://localhost:3000')

  def self.delete_item(external_list_id, external_item_id)
    endpoint = "/todolists/#{external_list_id}/todoitems/#{external_item_id}"

    response = delete(endpoint, timeout: 10)

    unless response.success?
      raise "Failed to delete remote item: #{response.code}"
    end

    response
  end

  def self.delete_list(external_list_id)
    endpoint = "/todolists/#{external_list_id}"

    response = delete(endpoint, timeout: 10)

    unless response.success?
      raise "Failed to delete remote list: #{response.code}"
    end

    response
  end
end
