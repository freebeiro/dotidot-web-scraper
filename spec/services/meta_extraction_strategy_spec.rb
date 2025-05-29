# frozen_string_literal: true

require "rails_helper"

RSpec.describe MetaExtractionStrategy do
  let(:html_content) do
    <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="description" content="Test description content">
          <meta name="keywords" content="test, keywords, meta">
          <meta property="og:title" content="Open Graph Title">
          <meta property="og:description" content="Open Graph Description">
          <meta property="og:image" content="https://example.com/image.jpg">
          <meta http-equiv="content-type" content="text/html; charset=UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <meta name="ROBOTS" content="NOINDEX, NOFOLLOW">
          <title>Test Page</title>
        </head>
        <body>
          <h1>Test Content</h1>
        </body>
      </html>
    HTML
  end

  let(:document) { Nokogiri::HTML(html_content) }
  let(:strategy) { described_class.new(document, fields) }

  describe ".call" do
    subject(:result) { described_class.call(document, fields) }

    context "with valid meta tag names" do
      let(:fields) { %w[description keywords] }

      it "returns success with extracted meta content" do
        expect(result).to include(
          success: true,
          data: {
            "description" => "Test description content",
            "keywords" => "test, keywords, meta"
          }
        )
      end

      it "includes results array with ExtractedField structs" do
        expect(result[:results]).to all(be_a(MetaExtractionStrategy::ExtractedField))
        expect(result[:results].map(&:value)).to eq(["Test description content", "test, keywords, meta"])
      end
    end

    context "with property-based meta tags (OpenGraph)" do
      let(:fields) { ["og:title", "og:description", "og:image"] }

      it "extracts property-based meta tags" do
        expect(result[:data]).to eq(
          "og:title" => "Open Graph Title",
          "og:description" => "Open Graph Description",
          "og:image" => "https://example.com/image.jpg"
        )
      end
    end

    context "with http-equiv meta tags" do
      let(:fields) { ["content-type"] }

      it "extracts http-equiv meta tags" do
        expect(result[:data]).to eq(
          "content-type" => "text/html; charset=UTF-8"
        )
      end
    end

    context "with case-insensitive matching" do
      let(:fields) { %w[robots VIEWPORT] }

      it "matches meta tags case-insensitively" do
        expect(result[:data]).to eq(
          "robots" => "NOINDEX, NOFOLLOW",
          "VIEWPORT" => "width=device-width, initial-scale=1.0"
        )
      end
    end

    context "with missing meta tags" do
      let(:fields) { %w[description nonexistent author] }

      it "returns nil for missing meta tags" do
        expect(result[:data]).to eq(
          "description" => "Test description content"
        )
        # Missing tags are not included in data hash
        expect(result[:data]).not_to have_key("nonexistent")
        expect(result[:data]).not_to have_key("author")
      end

      it "marks missing tags as successful with nil value in results" do
        missing_results = result[:results].select { |r| r.value.nil? }
        expect(missing_results.size).to eq(2)
        expect(missing_results).to all(have_attributes(error: nil))
      end
    end

    context "with hash field format" do
      let(:fields) do
        [
          { name: "description" },
          { name: "keywords", attribute: "content" },
          { name: "viewport", attribute: "content" }
        ]
      end

      it "handles hash field format correctly" do
        expect(result[:data]).to eq(
          "description" => "Test description content",
          "keywords" => "test, keywords, meta",
          "viewport" => "width=device-width, initial-scale=1.0"
        )
      end
    end

    context "with custom attribute extraction" do
      let(:html_content) do
        <<~HTML
          <html>
            <head>
              <meta name="custom" content="content-value" data-custom="custom-value">
            </head>
          </html>
        HTML
      end

      let(:fields) do
        [
          { name: "custom", attribute: "content" },
          { name: "custom", attribute: "data-custom" }
        ]
      end

      it "extracts specified attributes" do
        # NOTE: This will return the last one due to hash key collision
        # In real usage, field names should be unique
        expect(result[:data]["custom"]).to eq("custom-value")
      end
    end

    context "with nil document" do
      let(:document) { nil }
      let(:fields) { ["description"] }

      it "returns error response" do
        expect(result).to include(
          success: false,
          error: "Document is nil"
        )
      end
    end

    context "with nil fields" do
      let(:fields) { nil }

      it "returns success with empty data" do
        expect(result).to include(
          success: true,
          data: {}
        )
      end
    end

    context "with empty fields array" do
      let(:fields) { [] }

      it "returns success with empty data" do
        expect(result).to include(
          success: true,
          data: {}
        )
      end
    end

    context "with invalid field format" do
      let(:fields) { [123] }

      it "returns error response" do
        expect(result).to include(
          success: false,
          error: /Invalid meta field format/
        )
      end
    end

    context "with nil field name" do
      let(:fields) { [{ name: nil }] }

      it "returns error response" do
        expect(result).to include(
          success: false,
          error: "Meta tag name cannot be nil"
        )
      end
    end

    context "with empty field name" do
      let(:fields) { ["", "  "] }

      it "returns error response" do
        expect(result).to include(
          success: false,
          error: "Meta tag name cannot be empty"
        )
      end
    end
  end

  describe "#call" do
    let(:fields) { ["description"] }
    subject(:result) { strategy.call }

    it "logs errors when extraction fails" do
      allow(strategy).to receive(:extract_meta_tag).and_raise("Test error")

      expect(Rails.logger).to receive(:error).with(/Error extracting meta tag 'description': Test error/)

      result
    end
  end
end
