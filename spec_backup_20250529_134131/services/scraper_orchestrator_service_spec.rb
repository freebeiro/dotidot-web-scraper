# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScraperOrchestratorService do
  let(:valid_url) { "https://example.com" }
  let(:fields) { %w[title description] }
  let(:html_content) do
    "<html><head><title>Test Title</title></head><body><p class='description'>Test Description</p></body></html>"
  end
  let(:parsed_document) { Nokogiri::HTML(html_content) }

  let(:url_validator) { class_double(UrlValidatorService) }
  let(:http_client) { class_double(HttpClientService) }
  let(:html_parser) { class_double(HtmlParserService) }
  let(:css_strategy) { class_double(CssExtractionStrategy) }

  let(:service) do
    described_class.new(
      url_validator: url_validator,
      http_client: http_client,
      html_parser: html_parser,
      css_strategy: css_strategy
    )
  end

  describe ".call" do
    it "creates instance with default dependencies and calls it" do
      allow(UrlValidatorService).to receive(:call).and_return(valid_url)
      allow(HttpClientService).to receive(:call).and_return(double(body: html_content))
      allow(HtmlParserService).to receive(:call).and_return(parsed_document)
      allow(CssExtractionStrategy).to receive(:extract).and_return("Test Value")

      result = described_class.call(url: valid_url, fields: fields)

      expect(result).to be_success
    end
  end

  describe "#call" do
    context "with valid inputs" do
      before do
        allow(url_validator).to receive(:call).with(valid_url).and_return(valid_url)
        allow(http_client).to receive(:call).with(valid_url).and_return(double(body: html_content))
        allow(html_parser).to receive(:call).with(html_content).and_return(parsed_document)
        allow(css_strategy).to receive(:extract).and_return("Extracted Value")
      end

      it "orchestrates services in correct order" do
        expect(url_validator).to receive(:call).with(valid_url).ordered
        expect(http_client).to receive(:call).with(valid_url).ordered
        expect(html_parser).to receive(:call).with(html_content).ordered
        expect(css_strategy).to receive(:extract).exactly(2).times.ordered

        service.call(url: valid_url, fields: fields)
      end

      it "returns success response with extracted data" do
        result = service.call(url: valid_url, fields: fields)

        expect(result).to be_success
        expect(result.data).to include(
          url: valid_url,
          data: { "title" => "Extracted Value", "description" => "Extracted Value" }
        )
        expect(result.data[:scraped_at]).to be_present
        expect(result.cached).to be false
        expect(result.error).to be_nil
      end

      it "extracts data for each field" do
        expect(css_strategy).to receive(:extract).with(parsed_document, "title").and_return("Title Value")
        expect(css_strategy).to receive(:extract).with(parsed_document, "description").and_return("Description Value")

        result = service.call(url: valid_url, fields: fields)

        expect(result.data[:data]).to eq({
                                           "title" => "Title Value",
                                           "description" => "Description Value"
                                         })
      end

      context "with empty fields" do
        it "returns empty data hash" do
          result = service.call(url: valid_url, fields: [])

          expect(result).to be_success
          expect(result.data[:data]).to eq({})
        end
      end

      context "with hash field format" do
        let(:fields) do
          [
            { "name" => "page_title", "selector" => "title", "type" => "css" },
            { name: :meta_desc, selector: "description", type: :meta }
          ]
        end

        it "parses field configuration correctly" do
          expect(css_strategy).to receive(:extract).with(parsed_document, "title").and_return("Page Title")
          allow(parsed_document).to receive(:at_css).with("meta[name='description'], meta[property='description']")
                                                    .and_return(double(attribute: double(value: "Meta Description")))

          result = service.call(url: valid_url, fields: fields)

          expect(result.data[:data]).to eq({
                                             "page_title" => "Page Title",
                                             "meta_desc" => "Meta Description"
                                           })
        end
      end
    end

    context "with invalid URL" do
      it "returns error response when URL is nil" do
        result = service.call(url: nil, fields: fields)

        expect(result).not_to be_success
        expect(result.error).to be_a(ScraperErrors::ValidationError)
        expect(result.error.message).to include("URL is required")
      end

      it "returns error response when URL is empty" do
        result = service.call(url: "", fields: fields)

        expect(result).not_to be_success
        expect(result.error).to be_a(ScraperErrors::ValidationError)
        expect(result.error.message).to include("URL is required")
      end

      it "returns error response when URL validation fails" do
        allow(url_validator).to receive(:call).and_raise(ScraperErrors::SecurityError, "Blocked URL")

        result = service.call(url: "http://localhost", fields: fields)

        expect(result).not_to be_success
        expect(result.error).to be_a(ScraperErrors::SecurityError)
        expect(result.error.message).to eq("Blocked URL")
      end
    end

    context "when HTTP fetch fails" do
      before do
        allow(url_validator).to receive(:call).and_return(valid_url)
        allow(http_client).to receive(:call).and_raise(HTTP::Error, "Connection timeout")
      end

      it "returns error response with NetworkError" do
        result = service.call(url: valid_url, fields: fields)

        expect(result).not_to be_success
        expect(result.error).to be_a(ScraperErrors::NetworkError)
        expect(result.error.message).to include("Failed to fetch URL")
      end
    end

    context "when HTML parsing fails" do
      before do
        allow(url_validator).to receive(:call).and_return(valid_url)
        allow(http_client).to receive(:call).and_return(double(body: html_content))
        allow(html_parser).to receive(:call).and_raise(StandardError, "Invalid HTML")
      end

      it "returns error response with ParsingError" do
        result = service.call(url: valid_url, fields: fields)

        expect(result).not_to be_success
        expect(result.error).to be_a(ScraperErrors::ParsingError)
        expect(result.error.message).to include("Failed to parse HTML")
      end
    end

    context "when field extraction fails" do
      before do
        allow(url_validator).to receive(:call).and_return(valid_url)
        allow(http_client).to receive(:call).and_return(double(body: html_content))
        allow(html_parser).to receive(:call).and_return(parsed_document)
        allow(css_strategy).to receive(:extract).with(parsed_document, "title").and_return("Title Value")
        allow(css_strategy).to receive(:extract).with(parsed_document, "description").and_raise(StandardError,
                                                                                                "Selector error")
      end

      it "continues extracting other fields" do
        allow(Rails.logger).to receive(:warn)

        result = service.call(url: valid_url, fields: fields)

        expect(result).to be_success
        expect(result.data[:data]).to eq({ "title" => "Title Value" })
        expect(Rails.logger).to have_received(:warn).with(/Failed to extract field description/)
      end
    end

    context "with invalid field format" do
      let(:fields) { [123] }

      before do
        allow(url_validator).to receive(:call).and_return(valid_url)
        allow(http_client).to receive(:call).and_return(double(body: html_content))
        allow(html_parser).to receive(:call).and_return(parsed_document)
      end

      it "returns error response" do
        result = service.call(url: valid_url, fields: fields)

        expect(result).not_to be_success
        expect(result.error).to be_a(ScraperErrors::ValidationError)
        expect(result.error.message).to include("Invalid field format")
      end
    end

    context "with unknown extraction type" do
      let(:fields) { [{ "name" => "test", "selector" => "test", "type" => "xpath" }] }

      before do
        allow(url_validator).to receive(:call).and_return(valid_url)
        allow(http_client).to receive(:call).and_return(double(body: html_content))
        allow(html_parser).to receive(:call).and_return(parsed_document)
      end

      it "logs warning and skips field" do
        allow(Rails.logger).to receive(:warn)

        result = service.call(url: valid_url, fields: fields)

        expect(result).to be_success
        expect(result.data[:data]).to eq({})
        expect(Rails.logger).to have_received(:warn).with(/Unknown extraction type: xpath/)
      end
    end

    context "when unexpected error occurs" do
      before do
        allow(url_validator).to receive(:call).and_raise(RuntimeError, "Unexpected error")
      end

      it "wraps error in BaseError" do
        result = service.call(url: valid_url, fields: fields)

        expect(result).not_to be_success
        expect(result.error).to be_a(ScraperErrors::BaseError)
        expect(result.error.message).to include("Unexpected error")
      end
    end
  end
end
