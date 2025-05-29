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
  end

  describe "exception instantiation" do
    it "can instantiate ValidationError with a message" do
      error = ScraperErrors::ValidationError.new("Test validation error")
      expect(error.message).to eq("Test validation error")
      expect(error).to be_a(ScraperErrors::ValidationError)
    end

    it "can instantiate SecurityError with a message" do
      error = ScraperErrors::SecurityError.new("Test security error")
      expect(error.message).to eq("Test security error")
      expect(error).to be_a(ScraperErrors::SecurityError)
    end

    it "can instantiate NetworkError with a message" do
      error = ScraperErrors::NetworkError.new("Test network error")
      expect(error.message).to eq("Test network error")
      expect(error).to be_a(ScraperErrors::NetworkError)
    end
  end
end