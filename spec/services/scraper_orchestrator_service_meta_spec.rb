# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScraperOrchestratorService, "meta tag extraction" do
  let(:valid_url) { "https://example.com" }
  let(:html_content) do
    <<~HTML
      <html>
        <head>
          <meta name="description" content="Page description">
          <meta property="og:title" content="Open Graph Title">
          <meta property="og:image" content="https://example.com/image.jpg">
          <title>Page Title</title>
        </head>
        <body>
          <h1>Main Heading</h1>
          <p>Content paragraph</p>
        </body>
      </html>
    HTML
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

  before do
    allow(url_validator).to receive(:call).with(valid_url).and_return({ valid: true })
    allow(http_client).to receive(:call).with(valid_url).and_return({ success: true, body: html_content })
    allow(html_parser).to receive(:call).with(html_content).and_return({ success: true, doc: parsed_document })
  end

  describe "field partitioning" do
    context "with mixed CSS and meta fields" do
      let(:fields) do
        [
          { name: "title", selector: "h1" },
          { name: "description", type: "meta" },
          { name: "meta:og:title" },
          { name: "content", selector: "p" }
        ]
      end

      it "correctly separates CSS and meta fields" do
        expect(css_strategy).to receive(:call).with(
          parsed_document,
          [
            { name: "title", selector: "h1" },
            { name: "content", selector: "p" }
          ]
        ).and_return({ success: true, data: { "title" => "Main Heading", "content" => "Content paragraph" } })

        expect(meta_strategy).to receive(:call).with(
          parsed_document,
          [
            { name: "description", type: "meta" },
            { name: "og:title", original_name: "meta:og:title" }
          ]
        ).and_return({ success: true, data: { "description" => "Page description", "meta:og:title" => "Open Graph Title" } })

        result = service.call(url: valid_url, fields: fields)

        expect(result[:success]).to be true
        expect(result[:data]).to eq({
                                      "title" => "Main Heading",
                                      "content" => "Content paragraph",
                                      "description" => "Page description",
                                      "meta:og:title" => "Open Graph Title"
                                    })
      end
    end

    context "with only meta fields" do
      let(:fields) do
        [
          { name: "description", type: "meta" },
          { name: "og:title", type: "meta" },
          { name: "og:image", type: "meta" }
        ]
      end

      it "uses only meta strategy" do
        expect(css_strategy).not_to receive(:call)
        expect(meta_strategy).to receive(:call).with(
          parsed_document,
          fields
        ).and_return({
                       success: true,
                       data: {
                         "description" => "Page description",
                         "og:title" => "Open Graph Title",
                         "og:image" => "https://example.com/image.jpg"
                       }
                     })

        result = service.call(url: valid_url, fields: fields)

        expect(result[:success]).to be true
        expect(result[:data]).to eq({
                                      "description" => "Page description",
                                      "og:title" => "Open Graph Title",
                                      "og:image" => "https://example.com/image.jpg"
                                    })
      end
    end

    context "with only CSS fields" do
      let(:fields) do
        [
          { name: "title", selector: "h1" },
          { name: "content", selector: "p" }
        ]
      end

      it "uses only CSS strategy" do
        expect(meta_strategy).not_to receive(:call)
        expect(css_strategy).to receive(:call).with(
          parsed_document,
          fields
        ).and_return({
                       success: true,
                       data: {
                         "title" => "Main Heading",
                         "content" => "Content paragraph"
                       }
                     })

        result = service.call(url: valid_url, fields: fields)

        expect(result[:success]).to be true
      end
    end

    context "with meta: prefix convention" do
      let(:fields) do
        [
          { name: "title", selector: "title" },
          { name: "meta:description", selector: "description" },
          { name: "meta:og:title", selector: "og:title" }
        ]
      end

      it "identifies meta: prefix fields as meta tags" do
        expect(css_strategy).to receive(:call).with(
          parsed_document,
          [{ name: "title", selector: "title" }]
        ).and_return({ success: true, data: { "title" => "Page Title" } })

        expect(meta_strategy).to receive(:call).with(
          parsed_document,
          [
            { name: "description", original_name: "meta:description" },
            { name: "og:title", original_name: "meta:og:title" }
          ]
        ).and_return({
                       success: true,
                       data: {
                         "meta:description" => "Page description",
                         "meta:og:title" => "Open Graph Title"
                       }
                     })

        result = service.call(url: valid_url, fields: fields)

        expect(result[:success]).to be true
        expect(result[:data]).to include(
          "title" => "Page Title",
          "meta:description" => "Page description",
          "meta:og:title" => "Open Graph Title"
        )
      end
    end
  end

  describe "error handling" do
    context "when meta extraction fails" do
      let(:fields) do
        [
          { name: "title", selector: "h1" },
          { name: "description", type: "meta" }
        ]
      end

      it "propagates meta extraction errors" do
        allow(css_strategy).to receive(:call).and_return({ success: true, data: { "title" => "Main Heading" } })
        allow(meta_strategy).to receive(:call).and_return({ success: false, error: "Meta extraction failed" })

        result = service.call(url: valid_url, fields: fields)

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Meta extraction failed")
      end
    end
  end
end
