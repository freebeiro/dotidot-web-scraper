# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Data", type: :request do
  describe "GET /api/v1/data" do
    let(:valid_url) { "https://example.com" }
    let(:fields) { "title,description" }
    let(:scraped_data) do
      {
        url: valid_url,
        title: "Example Title",
        description: "Example Description",
        scraped_at: Time.current.iso8601
      }
    end

    context "with valid parameters" do
      before do
        allow(ScraperOrchestratorService).to receive(:call)
          .with(url: valid_url, fields: %w[title description])
          .and_return(OpenStruct.new(success?: true, data: scraped_data))
      end

      it "returns scraped data successfully" do
        get "/api/v1/data", params: { url: valid_url, fields: fields }

        expect(response).to have_http_status(:ok)

        json = response.parsed_body
        expect(json["data"]).to include("url" => valid_url)
        expect(json["meta"]).to include("version" => "1.0")
        expect(json["meta"]).to have_key("timestamp")
      end

      it "calls the orchestrator service with correct parameters" do
        expect(ScraperOrchestratorService).to receive(:call)
          .with(url: valid_url, fields: %w[title description])
          .once

        get "/api/v1/data", params: { url: valid_url, fields: fields }
      end
    end

    context "with missing URL parameter" do
      it "returns validation error" do
        get "/api/v1/data", params: { fields: fields }

        expect(response).to have_http_status(:unprocessable_entity)

        json = response.parsed_body
        expect(json["error"]).to be_a(Hash)
        expect(json["error"]["code"]).to eq("VALIDATION_ERROR")
        expect(json["error"]["message"]).to include("URL parameter is required")
      end
    end

    context "with empty URL parameter" do
      it "returns validation error" do
        get "/api/v1/data", params: { url: "", fields: fields }

        expect(response).to have_http_status(:unprocessable_entity)

        json = response.parsed_body
        expect(json["error"]["message"]).to include("URL parameter is required")
      end
    end

    context "without fields parameter" do
      before do
        allow(ScraperOrchestratorService).to receive(:call)
          .with(url: valid_url, fields: [])
          .and_return(OpenStruct.new(success?: true, data: scraped_data))
      end

      it "calls service with empty fields array" do
        expect(ScraperOrchestratorService).to receive(:call)
          .with(url: valid_url, fields: [])
          .once

        get "/api/v1/data", params: { url: valid_url }

        expect(response).to have_http_status(:ok)
      end
    end

    context "when service returns validation error" do
      before do
        allow(ScraperOrchestratorService).to receive(:call)
          .and_return(OpenStruct.new(
                        success?: false,
                        error: ScraperErrors::ValidationError.new("Invalid URL format")
                      ))
      end

      it "returns 422 status with error details" do
        get "/api/v1/data", params: { url: "not-a-url" }

        expect(response).to have_http_status(:unprocessable_entity)

        json = response.parsed_body
        expect(json["error"]["code"]).to eq("VALIDATION_ERROR")
        expect(json["error"]["message"]).to eq("Invalid URL format")
      end
    end

    context "when service returns network error" do
      before do
        allow(ScraperOrchestratorService).to receive(:call)
          .and_return(OpenStruct.new(
                        success?: false,
                        error: ScraperErrors::NetworkError.new("Connection timeout")
                      ))
      end

      it "returns 502 status with error details" do
        get "/api/v1/data", params: { url: valid_url }

        expect(response).to have_http_status(:bad_gateway)

        json = response.parsed_body
        expect(json["error"]["code"]).to eq("NETWORK_ERROR")
        expect(json["error"]["message"]).to eq("Connection timeout")
      end
    end

    context "when service raises unexpected error" do
      before do
        allow(ScraperOrchestratorService).to receive(:call)
          .and_raise(StandardError, "Unexpected error")
      end

      it "returns 500 status with error message" do
        get "/api/v1/data", params: { url: valid_url }

        expect(response).to have_http_status(:internal_server_error)

        json = response.parsed_body
        expect(json["error"]["code"]).to eq("INTERNAL_ERROR")
        expect(json["error"]["message"]).to eq("Unexpected error")
      end

      it "includes error details in development environment" do
        allow(Rails.env).to receive(:development?).and_return(true)

        get "/api/v1/data", params: { url: valid_url }

        json = response.parsed_body
        expect(json["error"]["message"]).to eq("Unexpected error")
      end

      it "excludes error details in production environment" do
        allow(Rails.env).to receive(:development?).and_return(false)
        allow(Rails.env).to receive(:production?).and_return(true)

        get "/api/v1/data", params: { url: valid_url }

        json = response.parsed_body
        expect(json["error"]["message"]).to eq("An unexpected error occurred")
      end
    end

    context "with multiple fields" do
      let(:multiple_fields) { "title,description,author,date" }

      before do
        allow(ScraperOrchestratorService).to receive(:call)
          .with(url: valid_url, fields: %w[title description author date])
          .and_return(OpenStruct.new(success?: true, data: scraped_data))
      end

      it "parses comma-separated fields correctly" do
        expect(ScraperOrchestratorService).to receive(:call)
          .with(url: valid_url, fields: %w[title description author date])
          .once

        get "/api/v1/data", params: { url: valid_url, fields: multiple_fields }

        expect(response).to have_http_status(:ok)
      end
    end

    context "with fields containing whitespace" do
      let(:fields_with_spaces) { "title , description , author" }

      before do
        allow(ScraperOrchestratorService).to receive(:call)
          .with(url: valid_url, fields: %w[title description author])
          .and_return(OpenStruct.new(success?: true, data: scraped_data))
      end

      it "strips whitespace from field names" do
        expect(ScraperOrchestratorService).to receive(:call)
          .with(url: valid_url, fields: %w[title description author])
          .once

        get "/api/v1/data", params: { url: valid_url, fields: fields_with_spaces }

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
