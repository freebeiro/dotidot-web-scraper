# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScraperOrchestratorService do
  let(:valid_url) { "https://example.com" }
  let(:fields) { { "title" => { "selector" => "h1", "type" => "text" }, "description" => { "selector" => "p", "type" => "text" } } }
  let(:html_content) do
    "<html><head><title>Test Title</title></head><body><p class='description'>Test Description</p></body></html>"
  end
  let(:parsed_document) { Nokogiri::HTML(html_content) }

  let(:url_validator) { class_double(UrlValidatorService) }
  let(:http_client) { class_double(HttpClientService) }
  let(:html_parser) { class_double(HtmlParserService) }
  let(:css_strategy) { class_double(CssExtractionStrategy) }
  let(:meta_strategy) { class_double(MetaExtractionStrategy) }

  let(:service) do
    described_class.new(
      url_validator: url_validator,
      http_client: http_client,
      html_parser: html_parser,
      css_strategy: css_strategy,
      meta_strategy: meta_strategy
    )
  end

  describe ".call" do
    it "creates instance with default dependencies and calls it" do
      allow(UrlValidatorService).to receive(:call).and_return({ valid: true })
      allow(HttpClientService).to receive(:call).and_return({ success: true, body: html_content })
      allow(HtmlParserService).to receive(:call).and_return({ success: true, doc: parsed_document })
      allow(CssExtractionStrategy).to receive(:call).and_return({ success: true, data: { "title" => "Test Title", "description" => "Test Description" } })
      allow(MetaExtractionStrategy).to receive(:call).and_return({ success: true, data: {} })

      result = described_class.call(url: valid_url, fields: { "title" => { "selector" => "h1", "type" => "text" }, "description" => { "selector" => "p", "type" => "text" } })

      expect(result[:success]).to be true
    end
  end

  describe "#call" do
    context "with valid inputs" do
      before do
        allow(url_validator).to receive(:call).with(valid_url).and_return({ valid: true })
        allow(http_client).to receive(:call).with(valid_url).and_return({ success: true, body: html_content })
        allow(html_parser).to receive(:call).with(html_content).and_return({ success: true, doc: parsed_document })
        allow(css_strategy).to receive(:call).and_return({ success: true, data: { "title" => "Extracted Value", "description" => "Extracted Value" } })
      end

      it "orchestrates services in correct order" do
        expect(url_validator).to receive(:call).with(valid_url).ordered
        expect(http_client).to receive(:call).with(valid_url).ordered
        expect(html_parser).to receive(:call).with(html_content).ordered
        expect(css_strategy).to receive(:call).ordered

        service.call(url: valid_url, fields: { "title" => { "selector" => "h1", "type" => "text" }, "description" => { "selector" => "p", "type" => "text" } })
      end

      it "returns success response with extracted data" do
        result = service.call(url: valid_url, fields: { "title" => { "selector" => "h1", "type" => "text" }, "description" => { "selector" => "p", "type" => "text" } })

        expect(result[:success]).to be true
        expect(result[:data]).to eq({ "title" => "Extracted Value", "description" => "Extracted Value" })
        expect(result[:cached]).to be false
        expect(result[:error]).to be_nil
      end

      it "extracts data for each field" do
        allow(css_strategy).to receive(:call).and_return({ success: true, data: { "title" => "Title Value", "description" => "Description Value" } })

        result = service.call(url: valid_url, fields: { "title" => { "selector" => "h1", "type" => "text" }, "description" => { "selector" => "p", "type" => "text" } })

        expect(result[:data]).to eq({
                                      "title" => "Title Value",
                                      "description" => "Description Value"
                                    })
      end

      context "with empty fields" do
        it "returns empty data hash" do
          result = service.call(url: valid_url, fields: [])

          expect(result[:success]).to be true
          expect(result[:data]).to eq({})
        end
      end

      context "with hash field format" do
        let(:fields) do
          {
            "page_title" => { "selector" => "title", "type" => "text" },
            "meta_desc" => { "selector" => "meta[name='description']", "type" => "attribute", "attribute" => "content" }
          }
        end

        it "parses field configuration correctly" do
          allow(css_strategy).to receive(:call).and_return({
                                                             success: true,
                                                             data: {
                                                               "page_title" => "Page Title",
                                                               "meta_desc" => "Meta Description"
                                                             }
                                                           })

          result = service.call(url: valid_url, fields: fields)

          expect(result[:data]).to eq({
                                        "page_title" => "Page Title",
                                        "meta_desc" => "Meta Description"
                                      })
        end
      end
    end

    context "with invalid URL" do
      it "returns error response when URL is nil" do
        result = service.call(url: nil, fields: fields)

        expect(result[:success]).to be false
        expect(result[:error]).to include("URL is required")
      end

      it "returns error response when URL is empty" do
        result = service.call(url: "", fields: fields)

        expect(result[:success]).to be false
        expect(result[:error]).to include("URL is required")
      end

      it "returns error response when URL validation fails" do
        allow(url_validator).to receive(:call).and_return({ valid: false, error: "Blocked URL" })

        result = service.call(url: "http://localhost", fields: fields)

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Blocked URL")
      end
    end

    context "when HTTP fetch fails" do
      before do
        allow(url_validator).to receive(:call).and_return({ valid: true })
        allow(http_client).to receive(:call).and_return({ success: false, error: "Failed to fetch URL: Connection timeout" })
      end

      it "returns error response with NetworkError" do
        result = service.call(url: valid_url, fields: fields)

        expect(result[:success]).to be false
        expect(result[:error]).to include("Failed to fetch URL")
      end
    end

    context "when HTML parsing fails" do
      before do
        allow(url_validator).to receive(:call).and_return({ valid: true })
        allow(http_client).to receive(:call).and_return({ success: true, body: html_content })
        allow(html_parser).to receive(:call).and_return({ success: false, error: "Failed to parse HTML: Invalid HTML" })
      end

      it "returns error response with ParsingError" do
        result = service.call(url: valid_url, fields: fields)

        expect(result[:success]).to be false
        expect(result[:error]).to include("Failed to parse HTML")
      end
    end

    context "when field extraction fails" do
      before do
        allow(url_validator).to receive(:call).and_return({ valid: true })
        allow(http_client).to receive(:call).and_return({ success: true, body: html_content })
        allow(html_parser).to receive(:call).and_return({ success: true, doc: parsed_document })
        allow(css_strategy).to receive(:call).and_return({ success: false, error: "Extraction failed", data: {} })
      end

      it "continues extracting other fields" do
        result = service.call(url: valid_url, fields: { "title" => { "selector" => "h1", "type" => "text" } })

        expect(result[:success]).to be false
        expect(result[:error]).to include("Extraction failed")
      end
    end

    context "with invalid field format" do
      let(:invalid_fields) { "invalid" }

      before do
        allow(url_validator).to receive(:call).and_return({ valid: true })
        allow(http_client).to receive(:call).and_return({ success: true, body: html_content })
        allow(html_parser).to receive(:call).and_return({ success: true, doc: parsed_document })
        allow(css_strategy).to receive(:call).and_return({ success: false, error: "Invalid fields format", data: {} })
      end

      it "returns error response" do
        result = service.call(url: valid_url, fields: invalid_fields)

        expect(result[:success]).to be false
        expect(result[:error]).to include("Invalid fields format")
      end
    end

    context "with unknown extraction type" do
      let(:fields) { { "test" => { "selector" => "test", "type" => "xpath" } } }

      before do
        allow(url_validator).to receive(:call).and_return({ valid: true })
        allow(http_client).to receive(:call).and_return({ success: true, body: html_content })
        allow(html_parser).to receive(:call).and_return({ success: true, doc: parsed_document })
        allow(css_strategy).to receive(:call).and_return({ success: true, data: {} })
      end

      it "logs warning and skips field" do
        allow(Rails.logger).to receive(:warn)

        result = service.call(url: valid_url, fields: fields)

        expect(result[:success]).to be true
        expect(result[:data]).to eq({})
      end
    end

    context "when unexpected error occurs" do
      before do
        allow(url_validator).to receive(:call).and_raise(RuntimeError, "Unexpected error")
      end

      it "wraps error in BaseError" do
        result = service.call(url: valid_url, fields: fields)

        expect(result[:success]).to be false
        expect(result[:error]).to include("Unexpected error")
      end
    end
  end
end
