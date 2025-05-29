# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe "Foundation Services Integration" do
  before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  after do
    WebMock.reset!
  end

  describe "end-to-end scraping workflow" do
    let(:target_url) { "https://example.com/products" }
    let(:html_content) do
      <<~HTML
        <html>
          <head>
            <title>Product Catalog</title>
            <meta name="description" content="Amazing products for sale">
          </head>
          <body>
            <header>
              <h1 class="site-title">Example Store</h1>
            </header>
            <main>
              <div class="products">
                <article class="product" data-id="123" data-category="electronics">
                  <h2 class="product-name">Laptop Pro</h2>
                  <p class="price">$999.99</p>
                  <p class="description">High-performance laptop with 16GB RAM</p>
                  <div class="stock">In Stock: <span class="count">5</span></div>
                </article>
                <article class="product" data-id="456" data-category="accessories">
                  <h2 class="product-name">Wireless Mouse</h2>
                  <p class="price">$49.99</p>
                  <p class="description">Ergonomic wireless mouse with precision tracking</p>
                  <div class="stock">In Stock: <span class="count">25</span></div>
                </article>
              </div>
            </main>
          </body>
        </html>
      HTML
    end

    it "successfully scrapes and extracts data from a valid URL" do
      # Step 1: Validate URL
      validation_result = UrlValidatorService.call(target_url)
      expect(validation_result[:valid]).to be true
      expect(validation_result[:url]).to eq(target_url)

      # Step 2: Fetch HTML content
      stub_request(:get, target_url)
        .to_return(status: 200, body: html_content, headers: { "Content-Type" => "text/html" })

      fetch_result = HttpClientService.call(validation_result[:url])
      expect(fetch_result[:success]).to be true
      expect(fetch_result[:body]).to eq(html_content)

      # Step 3: Parse HTML
      parse_result = HtmlParserService.call(fetch_result[:body])
      expect(parse_result[:success]).to be true
      expect(parse_result[:doc]).to be_a(Nokogiri::HTML::Document)

      # Step 4: Extract data using current API format
      fields = [
        { name: "page_title", selector: "title", type: "text" },
        { name: "site_title", selector: "h1.site-title", type: "text" },
        { name: "product_names", selector: ".product-name", type: "text", multiple: true },
        { name: "product_prices", selector: ".price", type: "text", multiple: true },
        { name: "product_ids", selector: ".product", type: "attribute", attribute: "data-id", multiple: true },
        { name: "stock_counts", selector: ".stock .count", type: "text", multiple: true }
      ]

      extract_result = CssExtractionStrategy.call(parse_result[:doc], fields)
      expect(extract_result[:success]).to be true

      data = extract_result[:data]
      expect(data["page_title"]).to eq("Product Catalog")
      expect(data["site_title"]).to eq("Example Store")
      expect(data["product_names"]).to eq(["Laptop Pro", "Wireless Mouse"])
      expect(data["product_prices"]).to eq(["$999.99", "$49.99"])
      expect(data["product_ids"]).to eq(%w[123 456])
      expect(data["stock_counts"]).to eq(%w[5 25])
    end

    it "handles redirects in the workflow" do
      redirect_url = "https://example.com/new-products"

      # Validate original URL
      validation_result = UrlValidatorService.call(target_url)
      expect(validation_result[:valid]).to be true

      # Fetch with redirect
      stub_request(:get, target_url)
        .to_return(status: 301, headers: { "Location" => redirect_url })
      stub_request(:get, redirect_url)
        .to_return(status: 200, body: html_content, headers: { "Content-Type" => "text/html" })

      fetch_result = HttpClientService.call(target_url)
      expect(fetch_result[:success]).to be true
      expect(fetch_result[:body]).to eq(html_content)

      # Continue with parsing and extraction
      parse_result = HtmlParserService.call(fetch_result[:body])
      expect(parse_result[:success]).to be true

      field = { name: "title", selector: "title", type: "text" }
      extract_result = CssExtractionStrategy.call(parse_result[:doc], [field])
      expect(extract_result[:data]["title"]).to eq("Product Catalog")
    end

    it "gracefully handles errors at each stage" do
      # Stage 1: Invalid URL
      invalid_url = "not-a-url"
      validation_result = UrlValidatorService.call(invalid_url)
      expect(validation_result[:valid]).to be false
      expect(validation_result[:error]).to include("Invalid URL format")

      # Stage 2: Network error
      valid_url = "https://example.com"
      stub_request(:get, valid_url).to_timeout

      fetch_result = HttpClientService.call(valid_url)
      expect(fetch_result[:success]).to be false
      expect(fetch_result[:error]).to include("timeout")

      # Stage 3: Invalid HTML
      parse_result = HtmlParserService.call(nil)
      expect(parse_result[:success]).to be false
      expect(parse_result[:error]).to include("HTML content cannot be nil")

      # Stage 4: Invalid selector
      doc = Nokogiri::HTML("<html><body></body></html>")
      field = { name: "bad", selector: "!!!invalid", type: "text" }
      extract_result = CssExtractionStrategy.call(doc, [field])
      expect(extract_result[:success]).to be false
    end

    describe "complex extraction scenarios" do
      let(:complex_html) do
        <<~HTML
          <html>
            <body>
              <div class="listing">
                <div class="item" data-price="19.99" data-available="true">
                  <h3>Item 1</h3>
                  <p class="desc">  Multiline
                    description with   extra  spaces  </p>
                  <ul class="tags">
                    <li>Tag1</li>
                    <li>Tag2</li>
                  </ul>
                </div>
                <div class="item" data-price="29.99" data-available="false">
                  <h3>Item 2</h3>
                  <p class="desc">Another description</p>
                  <ul class="tags">
                    <li>Tag3</li>
                  </ul>
                </div>
              </div>
            </body>
          </html>
        HTML
      end

      it "extracts nested and normalized data" do
        stub_request(:get, target_url)
          .to_return(status: 200, body: complex_html, headers: { "Content-Type" => "text/html" })

        # Full pipeline
        validation = UrlValidatorService.call(target_url)
        fetch = HttpClientService.call(validation[:url])
        parse = HtmlParserService.call(fetch[:body])

        fields = [
          {
            name: "item_titles",
            selector: ".item h3",
            type: "text",
            multiple: true
          },
          {
            name: "descriptions",
            selector: ".desc",
            type: "text",
            multiple: true
          },
          {
            name: "prices",
            selector: ".item",
            type: "attribute",
            attribute: "data-price",
            multiple: true
          },
          {
            name: "all_tags",
            selector: ".tags li",
            type: "text",
            multiple: true
          },
          {
            name: "available_items",
            selector: '[data-available="true"] h3',
            type: "text",
            multiple: true
          }
        ]

        extract = CssExtractionStrategy.call(parse[:doc], fields)

        expect(extract[:success]).to be true
        expect(extract[:data]["item_titles"]).to eq(["Item 1", "Item 2"])
        expect(extract[:data]["descriptions"]).to eq([
                                                       "Multiline description with extra spaces",
                                                       "Another description"
                                                     ])
        expect(extract[:data]["prices"]).to eq(["19.99", "29.99"])
        expect(extract[:data]["all_tags"]).to eq(%w[Tag1 Tag2 Tag3])
        expect(extract[:data]["available_items"]).to eq(["Item 1"])
      end
    end

    describe "performance and edge cases" do
      it "handles large HTML documents efficiently" do
        # Generate large HTML
        large_html = "<html><body>"
        1000.times do |i|
          large_html += <<~HTML
            <div class="item" data-id="#{i}">
              <h3 class="title">Item #{i}</h3>
              <p class="content">Content for item #{i} with some text</p>
            </div>
          HTML
        end
        large_html += "</body></html>"

        stub_request(:get, target_url)
          .to_return(status: 200, body: large_html, headers: { "Content-Type" => "text/html" })

        start_time = Time.current

        # Run full pipeline
        validation = UrlValidatorService.call(target_url)
        fetch = HttpClientService.call(validation[:url])
        parse = HtmlParserService.call(fetch[:body])

        fields = [
          {
            name: "all_titles",
            selector: ".title",
            type: "text",
            multiple: true
          },
          {
            name: "last_item_id",
            selector: ".item:last-child",
            type: "attribute",
            attribute: "data-id"
          }
        ]

        extract = CssExtractionStrategy.call(parse[:doc], fields)

        elapsed = Time.current - start_time

        expect(extract[:success]).to be true
        expect(extract[:data]["all_titles"].length).to eq(1000)
        expect(extract[:data]["last_item_id"]).to eq("999")
        expect(elapsed).to be < 2.0 # Should complete in under 2 seconds
      end

      it "handles malformed HTML with recovery" do
        malformed_html = <<~HTML
          <html>
            <body>
              <div class="container">
                <p>Unclosed paragraph
                <div class="inner">
                  <span>Some text</div>
                </span>
                <h1>Title</h1
              </div>
            </body>
          </html>
        HTML

        stub_request(:get, target_url)
          .to_return(status: 200, body: malformed_html, headers: { "Content-Type" => "text/html" })

        validation = UrlValidatorService.call(target_url)
        fetch = HttpClientService.call(validation[:url])
        parse = HtmlParserService.call(fetch[:body])

        expect(parse[:success]).to be true

        fields = [
          { name: "title", selector: "h1", type: "text" },
          { name: "text", selector: ".inner span", type: "text" }
        ]

        extract = CssExtractionStrategy.call(parse[:doc], fields)

        expect(extract[:success]).to be true
        expect(extract[:data]["title"]).to eq("Title")
        expect(extract[:data]["text"]).to eq("Some text")
      end

      it "handles encoding issues across the pipeline" do
        utf8_html = <<~HTML
          <html>
            <head>
              <meta charset="UTF-8">
            </head>
            <body>
              <h1>Café résumé</h1>
              <p class="emoji">Hello 👋 World 🌍</p>
              <p class="special">Smart quotes: "test" and 'another'</p>
            </body>
          </html>
        HTML

        stub_request(:get, target_url)
          .to_return(
            status: 200,
            body: utf8_html.encode("UTF-8"),
            headers: { "Content-Type" => "text/html; charset=utf-8" }
          )

        validation = UrlValidatorService.call(target_url)
        fetch = HttpClientService.call(validation[:url])
        parse = HtmlParserService.call(fetch[:body])

        fields = [
          { name: "title", selector: "h1", type: "text" },
          { name: "emoji", selector: ".emoji", type: "text" },
          { name: "quotes", selector: ".special", type: "text" }
        ]

        extract = CssExtractionStrategy.call(parse[:doc], fields)

        expect(extract[:success]).to be true
        expect(extract[:data]["title"]).to include("Café")
        expect(extract[:data]["emoji"]).to include("👋")
        expect(extract[:data]["emoji"]).to include("🌍")
        expect(extract[:data]["quotes"]).to include('"')
      end
    end

    describe "security scenarios" do
      it "blocks SSRF attempts through the pipeline" do
        # Try various SSRF vectors
        ssrf_urls = [
          "http://localhost/admin",
          "http://127.0.0.1:8080",
          "http://192.168.1.1",
          "http://169.254.169.254/latest/meta-data/",
          "http://[::1]",
          "file:///etc/passwd"
        ]

        ssrf_urls.each do |url|
          validation = UrlValidatorService.call(url)
          expect(validation[:valid]).to be false
          expect(validation[:error]).to match(/private|reserved|protocol/)
        end
      end

      it "handles content type validation" do
        # Try to fetch non-HTML content
        stub_request(:get, target_url)
          .to_return(
            status: 200,
            body: "Binary content",
            headers: { "Content-Type" => "application/pdf" }
          )

        validation = UrlValidatorService.call(target_url)
        fetch = HttpClientService.call(validation[:url])

        expect(fetch[:success]).to be false
        expect(fetch[:error]).to include("Invalid content type")
      end

      it "enforces size limits through the pipeline" do
        # Create 11MB HTML
        huge_html = "<html><body><p>#{'x' * 11_000_000}</p></body></html>"

        stub_request(:get, target_url)
          .to_return(status: 200, body: huge_html, headers: { "Content-Type" => "text/html" })

        validation = UrlValidatorService.call(target_url)
        fetch = HttpClientService.call(validation[:url])

        expect(fetch[:success]).to be false
        expect(fetch[:error]).to include("Response too large")
      end
    end
  end
end
