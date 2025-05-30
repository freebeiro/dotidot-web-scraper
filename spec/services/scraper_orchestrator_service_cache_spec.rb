# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScraperOrchestratorService, type: :service do
  let(:valid_url) { "https://example.com" }
  let(:fields) { [{ "name" => "title", "selector" => "h1" }] }
  let(:html_content) { "<html><head><title>Test</title></head><body><h1>Test Title</h1></body></html>" }
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

  describe "caching integration" do
    before do
      allow(url_validator).to receive(:call).and_return({ valid: true })
    end

    context "when data is cached" do
      let(:cached_data) do
        {
          success: true,
          data: { "title" => "Cached Title" },
          cached: false
        }
      end

      it "returns cached data without scraping" do
        expect(CacheService).to receive(:get).with(url: valid_url, fields: fields)
                                             .and_return(cached_data)

        # Should not call any scraping services
        expect(http_client).not_to receive(:call)
        expect(html_parser).not_to receive(:call)
        expect(css_strategy).not_to receive(:call)

        result = service.call(url: valid_url, fields: fields)

        expect(result[:success]).to be true
        expect(result[:cached]).to be true
        expect(result[:data]).to eq({ "title" => "Cached Title" })
      end
    end

    context "when cache is empty" do
      let(:fresh_data) { { "title" => "Fresh Title" } }

      before do
        allow(CacheService).to receive(:get).and_return(nil)
        allow(http_client).to receive(:call).and_return({ success: true, body: html_content })
        allow(html_parser).to receive(:call).and_return({ success: true, doc: parsed_document })
        allow(css_strategy).to receive(:call).and_return({ success: true, data: fresh_data })
        allow(meta_strategy).to receive(:call).and_return({ success: true, data: {} })
      end

      it "performs scraping and caches the result" do
        expect(CacheService).to receive(:set).with(
          url: valid_url,
          fields: fields,
          data: hash_including(success: true, data: fresh_data, cached: false)
        )

        result = service.call(url: valid_url, fields: fields)

        expect(result[:success]).to be true
        expect(result[:cached]).to be false
        expect(result[:data]).to eq(fresh_data)
      end
    end

    context "when cache check fails" do
      before do
        allow(CacheService).to receive(:get).and_raise(Redis::ConnectionError.new("Cache error"))
        allow(Rails.logger).to receive(:warn)
        allow(http_client).to receive(:call).and_return({ success: true, body: html_content })
        allow(html_parser).to receive(:call).and_return({ success: true, doc: parsed_document })
        allow(css_strategy).to receive(:call).and_return({ success: true, data: { "title" => "Fresh Title" } })
        allow(meta_strategy).to receive(:call).and_return({ success: true, data: {} })
      end

      it "proceeds with scraping gracefully" do
        expect(Rails.logger).to receive(:warn).with(/Cache check failed/)

        result = service.call(url: valid_url, fields: fields)

        expect(result[:success]).to be true
        expect(result[:cached]).to be false
      end
    end

    context "when cache storage fails" do
      before do
        allow(CacheService).to receive(:get).and_return(nil)
        allow(CacheService).to receive(:set).and_raise(Redis::ConnectionError.new("Cache error"))
        allow(Rails.logger).to receive(:warn)
        allow(http_client).to receive(:call).and_return({ success: true, body: html_content })
        allow(html_parser).to receive(:call).and_return({ success: true, doc: parsed_document })
        allow(css_strategy).to receive(:call).and_return({ success: true, data: { "title" => "Fresh Title" } })
        allow(meta_strategy).to receive(:call).and_return({ success: true, data: {} })
      end

      it "returns the result even if caching fails" do
        expect(Rails.logger).to receive(:warn).with(/Cache storage failed/)

        result = service.call(url: valid_url, fields: fields)

        expect(result[:success]).to be true
        expect(result[:cached]).to be false
      end
    end

    context "when scraping fails" do
      before do
        allow(CacheService).to receive(:get).and_return(nil)
        allow(http_client).to receive(:call).and_return({ success: false, error: "Network error" })
      end

      it "does not cache failed results" do
        expect(CacheService).not_to receive(:set)

        result = service.call(url: valid_url, fields: fields)

        expect(result[:success]).to be false
      end
    end
  end

  describe "cache integration with different field types" do
    before do
      allow(url_validator).to receive(:call).and_return({ valid: true })
      allow(CacheService).to receive(:get).and_return(nil)
      allow(http_client).to receive(:call).and_return({ success: true, body: html_content })
      allow(html_parser).to receive(:call).and_return({ success: true, doc: parsed_document })
    end

    context "with CSS fields only" do
      let(:css_fields) { [{ "name" => "title", "selector" => "h1" }] }

      it "caches CSS extraction results" do
        allow(css_strategy).to receive(:call).and_return({ success: true, data: { "title" => "CSS Title" } })
        allow(meta_strategy).to receive(:call).and_return({ success: true, data: {} })

        expect(CacheService).to receive(:set).with(
          url: valid_url,
          fields: css_fields,
          data: hash_including(success: true, data: { "title" => "CSS Title" })
        )

        service.call(url: valid_url, fields: css_fields)
      end
    end

    context "with meta fields only" do
      let(:meta_fields) { [{ "name" => "description", "type" => "meta" }] }

      it "caches meta extraction results" do
        allow(css_strategy).to receive(:call).and_return({ success: true, data: {} })
        allow(meta_strategy).to receive(:call).and_return({ success: true, data: { "description" => "Meta Description" } })

        expect(CacheService).to receive(:set).with(
          url: valid_url,
          fields: meta_fields,
          data: hash_including(success: true, data: { "description" => "Meta Description" })
        )

        service.call(url: valid_url, fields: meta_fields)
      end
    end

    context "with mixed CSS and meta fields" do
      let(:mixed_fields) do
        [
          { "name" => "title", "selector" => "h1" },
          { "name" => "description", "type" => "meta" }
        ]
      end

      it "caches combined extraction results" do
        allow(css_strategy).to receive(:call).and_return({ success: true, data: { "title" => "CSS Title" } })
        allow(meta_strategy).to receive(:call).and_return({ success: true, data: { "description" => "Meta Description" } })

        expect(CacheService).to receive(:set).with(
          url: valid_url,
          fields: mixed_fields,
          data: hash_including(
            success: true,
            data: {
              "title" => "CSS Title",
              "description" => "Meta Description"
            }
          )
        )

        service.call(url: valid_url, fields: mixed_fields)
      end
    end
  end
end
