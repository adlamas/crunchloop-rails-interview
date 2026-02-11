require 'rails_helper'
require 'webmock/rspec'

RSpec.describe ExternalTodoApiUpdaterService do
  let(:base_url) { "http://localhost:3001" }
  let(:ext_list_id) { "L_999" }
  let(:ext_item_id) { "I_888" }

  before do
    allow(ExternalTodoApiUpdaterService).to receive(:base_uri).and_return(base_url)
  end

  describe '.update_item' do
    let(:endpoint) { "#{base_url}/todolists/#{ext_list_id}/todoitems/#{ext_item_id}" }
    let(:params) { { content: "New Content", completed: true } }

    it 'sends a PATCH request with the correct payload to the item endpoint' do
      expected_body = { description: "New Content", completed: true }.to_json

      stub_request(:patch, endpoint)
        .with(body: expected_body)
        .to_return(status: 200, body: "", headers: { 'Content-Type' => 'application/json' })

      response = described_class.update_item(ext_list_id, ext_item_id, params)

      expect(response.success?).to be true
      expect(WebMock).to have_requested(:patch, endpoint).once
    end

    it 'raises an error if the API returns a 500 status code' do
      stub_request(:patch, endpoint).to_return(status: 500)

      expect {
        described_class.update_item(ext_list_id, ext_item_id, params)
      }.to raise_error(RuntimeError, /Failed to update remote item: 500/)
    end
  end
end
