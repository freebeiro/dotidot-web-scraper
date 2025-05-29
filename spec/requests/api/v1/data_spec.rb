# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Data", type: :request do
  describe "GET /api/v1/data" do
    let(:valid_url) { "https://example.com" }
    let(:fields) { '{"title": {"selector": "h1", "type": "text"}, "description": {"selector": "meta[name=description]", "type": "attribute", "attribute": "content"}}' }
    let(:scraped_data) do
      {
        "title" => "Example Title",
        "description" => "Example Description"
      }
    end

    context "with valid parameters" do
      before do
        allow(ScraperOrchestratorService).to receive(:call)
          .with(url: valid_url, fields: hash_including("title", "description"))
          .and_return(success: true, data: scraped_data)
      end

      it "returns scraped data successfully" do
        get "/api/v1/data", params: { url: valid_url, fields: fields }

        expect(response).to have_http_status(:ok)

        json = response.parsed_body
        expect(json["success"]).to be true
        expect(json["data"]).to include("title" => "Example Title")
        expect(json["data"]).to include("description" => "Example Description")
      end

      it "calls the orchestrator service with correct parameters" do
        expect(ScraperOrchestratorService).to receive(:call)
          .with(url: valid_url, fields: hash_including("title", "description"))
          .once

        get "/api/v1/data", params: { url: valid_url, fields: fields }
      end
    end

    context "with missing URL parameter" do
      it "returns validation error" do
        get "/api/v1/data", params: { fields: fields }

        expect(response).to have_http_status(:bad_request)

        json = response.parsed_body
        expect(json["success"]).to be false
        expect(json["error"]).to include("URL parameter is required")
      end
    end

    context "with empty URL parameter" do
      it "returns validation error" do
        get "/api/v1/data", params: { url: "", fields: fields }

        expect(response).to have_http_status(:bad_request)

        json = response.parsed_body
        expect(json["success"]).to be false
        expect(json["error"]).to include("URL parameter is required")
      end
    end

    context "without fields parameter" do
      it "returns validation error" do
        get "/api/v1/data", params: { url: valid_url }

        expect(response).to have_http_status(:bad_request)
        json = response.parsed_body
        expect(json["success"]).to be false
        expect(json["error"]).to include("fields parameter is required")
      end
    end

    context "when service returns validation error" do
      before do
        allow(ScraperOrchestratorService).to receive(:call)
          .and_return(success: false, error: "Invalid URL format")
      end

      it "returns 400 status with error details" do
        get "/api/v1/data", params: { url: "not-a-url", fields: fields }

        expect(response).to have_http_status(:bad_request)

        json = response.parsed_body
        expect(json["success"]).to be false
        expect(json["error"]).to eq("Invalid URL format")
      end
    end

    context "when service returns network error" do
      before do
        allow(ScraperOrchestratorService).to receive(:call)
          .and_raise(ScraperErrors::NetworkError, "Connection timeout")
      end

      it "returns 400 status with error details" do
        get "/api/v1/data", params: { url: valid_url, fields: fields }

        expect(response).to have_http_status(:bad_request)

        json = response.parsed_body
        expect(json["success"]).to be false
        expect(json["error"]).to eq("Connection timeout")
      end
    end

    context "when service raises unexpected error" do
      before do
        allow(ScraperOrchestratorService).to receive(:call)
          .and_raise(StandardError, "Unexpected error")
      end

      it "returns 400 status with error message" do
        get "/api/v1/data", params: { url: valid_url, fields: fields }

        expect(response).to have_http_status(:bad_request)

        json = response.parsed_body
        expect(json["success"]).to be false
        expect(json["error"]).to eq("Unexpected error")
      end

    end

  end
end
