# frozen_string_literal: true

require "rails_helper"

RSpec.describe ErrorHandling, type: :controller do
  controller(ApplicationController) do
    include ErrorHandling

    def index
      case params[:error_type]
      when "validation"
        raise ScraperErrors::ValidationError.new("Invalid input", context: { field: "url" })
      when "security"
        raise ScraperErrors::SecurityError, "Blocked URL"
      when "network"
        raise ScraperErrors::NetworkError.new("Connection failed", retry_after: 30)
      when "parsing"
        raise ScraperErrors::ParsingError, "Invalid HTML"
      when "timeout"
        raise ScraperErrors::TimeoutError.new("Request timeout", timeout: 10)
      when "rate_limit"
        raise ScraperErrors::RateLimitError.new("Too many requests", retry_after: 60)
      when "parameter_missing"
        raise ActionController::ParameterMissing, :url
      when "standard"
        raise StandardError, "Unexpected error"
      else
        render json: { success: true }
      end
    end
  end

  before do
    routes.draw { get "index" => "anonymous#index" }
    allow(SecureRandom).to receive(:uuid).and_return("test-error-id")
    request.headers["X-Request-Id"] = "test-request-id"
  end

  describe "error handling" do
    context "with validation error" do
      it "returns 422 with proper error format" do
        get :index, params: { error_type: "validation" }

        expect(response).to have_http_status(:unprocessable_entity)

        json = response.parsed_body
        expect(json["error"]["code"]).to eq("VALIDATION_ERROR")
        expect(json["error"]["message"]).to eq("Invalid input")
        expect(json["error"]["error_id"]).to eq("test-error-id")
        expect(json["error"]["request_id"]).to eq("test-request-id")
        expect(json["error"]["timestamp"]).to be_present
      end

      it "logs at warn level" do
        expect(Rails.logger).to receive(:warn).with(/Error occurred: Invalid input/)
        get :index, params: { error_type: "validation" }
      end
    end

    context "with security error" do
      it "returns 403 with proper error format" do
        get :index, params: { error_type: "security" }

        expect(response).to have_http_status(:forbidden)

        json = response.parsed_body
        expect(json["error"]["code"]).to eq("SECURITY_ERROR")
        expect(json["error"]["message"]).to eq("Blocked URL")
      end

      it "logs at error level" do
        expect(Rails.logger).to receive(:error).with(/Error occurred: Blocked URL/)
        get :index, params: { error_type: "security" }
      end
    end

    context "with network error" do
      it "returns 502 with retry information" do
        get :index, params: { error_type: "network" }

        expect(response).to have_http_status(:bad_gateway)

        json = response.parsed_body
        expect(json["error"]["code"]).to eq("NETWORK_ERROR")
        expect(json["error"]["retry_after"]).to eq(30)
      end
    end

    context "with timeout error" do
      it "returns 502 with timeout context" do
        get :index, params: { error_type: "timeout" }

        expect(response).to have_http_status(:bad_gateway)

        json = response.parsed_body
        expect(json["error"]["code"]).to eq("TIMEOUT_ERROR")
      end
    end

    context "with rate limit error" do
      it "returns 429 with retry_after" do
        get :index, params: { error_type: "rate_limit" }

        expect(response).to have_http_status(:too_many_requests)

        json = response.parsed_body
        expect(json["error"]["code"]).to eq("RATE_LIMIT_ERROR")
        expect(json["error"]["retry_after"]).to eq(60)
      end
    end

    context "with parameter missing" do
      it "returns 400 with proper message" do
        get :index, params: { error_type: "parameter_missing" }

        expect(response).to have_http_status(:bad_request)

        json = response.parsed_body
        expect(json["error"]["code"]).to eq("MISSING_PARAMETER")
        expect(json["error"]["message"]).to include("Missing required parameter: url")
      end
    end

    context "with standard error" do
      it "returns 500 with generic message in production" do
        allow(Rails.env).to receive(:production?).and_return(true)

        get :index, params: { error_type: "standard" }

        expect(response).to have_http_status(:internal_server_error)

        json = response.parsed_body
        expect(json["error"]["code"]).to eq("INTERNAL_ERROR")
        expect(json["error"]["message"]).to eq("An unexpected error occurred")
      end

      it "includes debug info in development" do
        allow(Rails.env).to receive(:development?).and_return(true)

        get :index, params: { error_type: "standard" }

        json = response.parsed_body
        expect(json["error"]["debug"]).to be_present
        expect(json["error"]["debug"]["class"]).to eq("ScraperErrors::BaseError")
        expect(json["error"]["debug"]["backtrace"]).to be_an(Array)
      end
    end

    context "error tracking" do
      it "notifies error tracker for server errors" do
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)

        expect(Rails.logger).to receive(:info).with(/Error notification would be sent to tracking service/).at_least(:once)

        get :index, params: { error_type: "standard" }
      end

      it "does not notify for client errors in production" do
        allow(Rails.env).to receive(:production?).and_return(true)
        expect(Rails.logger).not_to receive(:info).with(/Error notification would be sent to tracking service/)

        get :index, params: { error_type: "validation" }
      end

      it "always notifies for security errors" do
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)

        expect(Rails.logger).to receive(:info).with(/Error notification would be sent to tracking service/).at_least(:once)

        get :index, params: { error_type: "security" }
      end
    end
  end
end
