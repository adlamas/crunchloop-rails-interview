require 'rails_helper'
require 'webmock/rspec'

RSpec.describe ExternalTodoApiDestroyerService do
  let(:base_url) { "http://localhost:3001" }
  let(:ext_list_id) { "L1" }
  let(:ext_item_id) { "I1" }
  let(:endpoint) { "#{base_url}/todolists/#{ext_list_id}/todoitems/#{ext_item_id}" }

  before do
    allow(ExternalTodoApiDestroyerService).to receive(:base_uri).and_return(base_url)
  end

  describe '.delete_item' do
    it 'sends a DELETE request to the correct endpoint' do
      stub_request(:delete, endpoint).to_return(status: 200)

      response = described_class.delete_item(ext_list_id, ext_item_id)

      expect(response.success?).to be true
      expect(WebMock).to have_requested(:delete, endpoint).once
    end

    it 'raises an error if the API returns an error code' do
      stub_request(:delete, endpoint).to_return(status: 500)

      expect {
        described_class.delete_item(ext_list_id, ext_item_id)
      }.to raise_error(RuntimeError, /Failed to delete remote item: 500/)
    end

    it 'raises an error for 404 responses' do
      stub_request(:delete, endpoint).to_return(status: 404)

      expect {
        described_class.delete_item(ext_list_id, ext_item_id)
      }.to raise_error(RuntimeError, /Failed to delete remote item: 404/)
    end
  end

  describe '.delete_list' do
    let(:list_endpoint) { "#{base_url}/todolists/#{ext_list_id}" }

    it 'sends a DELETE request to the specific list endpoint' do
      stub_request(:delete, list_endpoint).to_return(status: 200)

      response = described_class.delete_list(ext_list_id)

      expect(response.success?).to be true
      expect(WebMock).to have_requested(:delete, list_endpoint).once
    end

    it 'raises an error if the API returns a 500 status code' do
      stub_request(:delete, list_endpoint).to_return(status: 500)

      expect {
        described_class.delete_list(ext_list_id)
      }.to raise_error(RuntimeError, /Failed to delete remote list: 500/)
    end

    it 'raises an error if the API returns a 404 status code' do
      stub_request(:delete, list_endpoint).to_return(status: 404)

      expect {
        described_class.delete_list(ext_list_id)
      }.to raise_error(RuntimeError, /Failed to delete remote list: 404/)
    end
  end
end
