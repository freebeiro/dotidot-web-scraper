# frozen_string_literal: true

require "rails_helper"
require_relative "../../lib/scraper_errors"

RSpec.describe ScraperErrors do
  describe "exception hierarchy" do
    it "defines BaseError as a subclass of StandardError" do
      expect(ScraperErrors::BaseError).to be < StandardError
    end

    it "defines ValidationError as a subclass of BaseError" do
      expect(ScraperErrors::ValidationError).to be < ScraperErrors::BaseError
    end

    it "defines SecurityError as a subclass of BaseError" do
      expect(ScraperErrors::SecurityError).to be < ScraperErrors::BaseError
    end

    it "defines NetworkError as a subclass of BaseError" do
      expect(ScraperErrors::NetworkError).to be < ScraperErrors::BaseError
    end

    it "defines ParsingError as a subclass of BaseError" do
      expect(ScraperErrors::ParsingError).to be < ScraperErrors::BaseError
    end

    it "defines TimeoutError as a subclass of NetworkError" do
      expect(ScraperErrors::TimeoutError).to be < ScraperErrors::NetworkError
    end

    it "defines RateLimitError as a subclass of BaseError" do
      expect(ScraperErrors::RateLimitError).to be < ScraperErrors::BaseError
    end
  end

  describe "BaseError" do
    it "accepts message, error_code, context, and suggested_action" do
      error = ScraperErrors::BaseError.new(
        "Test error",
        error_code: "TEST_ERROR",
        context: { url: "http://example.com" },
        suggested_action: "Try again"
      )

      expect(error.message).to eq("Test error")
      expect(error.error_code).to eq("TEST_ERROR")
      expect(error.context).to eq({ url: "http://example.com" })
      expect(error.suggested_action).to eq("Try again")
    end

    it "generates error_code from class name if not provided" do
      error = ScraperErrors::BaseError.new("Test")
      expect(error.error_code).to eq("BASE_ERROR")
    end
  end

  describe "ValidationError" do
    it "has default error_code and suggested_action" do
      error = ScraperErrors::ValidationError.new("Invalid URL")

      expect(error.error_code).to eq("VALIDATION_ERROR")
      expect(error.suggested_action).to eq("Please check your input and try again")
    end

    it "allows overriding defaults" do
      error = ScraperErrors::ValidationError.new(
        "Invalid URL",
        error_code: "INVALID_URL",
        suggested_action: "Use a valid HTTP/HTTPS URL"
      )

      expect(error.error_code).to eq("INVALID_URL")
      expect(error.suggested_action).to eq("Use a valid HTTP/HTTPS URL")
    end
  end

  describe "SecurityError" do
    it "has appropriate defaults" do
      error = ScraperErrors::SecurityError.new("SSRF attempt")

      expect(error.error_code).to eq("SECURITY_ERROR")
      expect(error.suggested_action).to eq("The requested URL is not allowed for security reasons")
    end
  end

  describe "NetworkError" do
    it "supports retry_after and status_code" do
      error = ScraperErrors::NetworkError.new(
        "Server error",
        retry_after: 30,
        status_code: 503
      )

      expect(error.retry_after).to eq(30)
      expect(error.status_code).to eq(503)
      expect(error.error_code).to eq("NETWORK_ERROR")
    end
  end

  describe "TimeoutError" do
    it "inherits from NetworkError" do
      error = ScraperErrors::TimeoutError.new
      expect(error).to be_a(ScraperErrors::NetworkError)
    end

    it "includes timeout in context" do
      error = ScraperErrors::TimeoutError.new("Request timeout", timeout: 15)

      expect(error.error_code).to eq("TIMEOUT_ERROR")
      expect(error.context[:timeout]).to eq(15)
      expect(error.suggested_action).to eq("The request took too long. Please try again")
    end
  end

  describe "RateLimitError" do
    it "has retry_after with default" do
      error = ScraperErrors::RateLimitError.new
      expect(error.retry_after).to eq(60)
    end

    it "accepts custom retry_after" do
      error = ScraperErrors::RateLimitError.new("Too many requests", retry_after: 120)

      expect(error.retry_after).to eq(120)
      expect(error.error_code).to eq("RATE_LIMIT_ERROR")
      expect(error.suggested_action).to include("Too many requests")
    end
  end

  describe "ParsingError" do
    it "has appropriate defaults" do
      error = ScraperErrors::ParsingError.new("Malformed HTML")

      expect(error.error_code).to eq("PARSING_ERROR")
      expect(error.suggested_action).to eq("The webpage content could not be parsed")
    end
  end
end
