# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dotidot Challenge API", type: :request do
  let(:valid_html) do
    <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="description" content="Test description">
          <meta name="keywords" content="test, keywords">
          <meta property="og:title" content="OpenGraph Title">
        </head>
        <body>
          <div class="price">$99.99</div>
          <h1 class="title">Product Title</h1>
          <div class="product" data-id="123">
            <span class="name">Product Name</span>
            <p class="description">Product description text</p>
          </div>
          <ul class="features">
            <li>Feature 1</li>
            <li>Feature 2</li>
          </ul>
        </body>
      </html>
    HTML
  end

  # Task #1: CSS Selector Extraction
  describe "CSS Selector Extraction (Task #1)" do
    context "GET requests with JSON fields parameter" do
      it "extracts single text value from CSS selector" do
        WebMock.stub_request(:get, "https://example.com/product")
               .to_return(status: 200, body: valid_html, headers: { "Content-Type" => "text/html" })

        get "/api/v1/data", params: {
          url: "https://example.com/product",
          fields: '{"price": {"selector": ".price", "type": "text"}}'
        }

        expect(response).to have_http_status(:ok)
        data = response.parsed_body
        
        expect(data["price"]).to eq("$99.99")
      end

      it "extracts multiple fields from CSS selectors" do
        WebMock.stub_request(:get, "https://example.com/product")
               .to_return(status: 200, body: valid_html, headers: { "Content-Type" => "text/html" })

        get "/api/v1/data", params: {
          url: "https://example.com/product",
          fields: JSON.generate({
                                  "price" => { "selector" => ".price", "type" => "text" },
                                  "title" => { "selector" => ".title", "type" => "text" },
                                  "name" => { "selector" => ".name", "type" => "text" }
                                })
        }

        expect(response).to have_http_status(:ok)
        data = response.parsed_body
        
        expect(data["price"]).to eq("$99.99")
        expect(data["title"]).to eq("Product Title")
        expect(data["name"]).to eq("Product Name")
      end

      it "extracts attributes from elements" do
        WebMock.stub_request(:get, "https://example.com/product")
               .to_return(status: 200, body: valid_html, headers: { "Content-Type" => "text/html" })

        get "/api/v1/data", params: {
          url: "https://example.com/product",
          fields: JSON.generate({
                                  "product_id" => { "selector" => ".product", "type" => "attribute", "attribute" => "data-id" }
                                })
        }

        expect(response).to have_http_status(:ok)
        data = response.parsed_body
        
        expect(data["product_id"]).to eq("123")
      end

      it "extracts multiple elements as array" do
        WebMock.stub_request(:get, "https://example.com/product")
               .to_return(status: 200, body: valid_html, headers: { "Content-Type" => "text/html" })

        get "/api/v1/data", params: {
          url: "https://example.com/product",
          fields: JSON.generate({
                                  "features" => { "selector" => ".features li", "type" => "text", "multiple" => true }
                                })
        }

        expect(response).to have_http_status(:ok)
        data = response.parsed_body
        
        expect(data["features"]).to eq(["Feature 1", "Feature 2"])
      end
    end

    context "POST requests with JSON body" do
      it "extracts data via POST request" do
        WebMock.stub_request(:get, "https://example.com/product")
               .to_return(status: 200, body: valid_html, headers: { "Content-Type" => "text/html" })

        post "/api/v1/data", params: {
          url: "https://example.com/product",
          fields: {
            "price" => { "selector" => ".price", "type" => "text" },
            "title" => { "selector" => ".title", "type" => "text" }
          }
        }.to_json, headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:ok)
        data = response.parsed_body
        
        expect(data["price"]).to eq("$99.99")
        expect(data["title"]).to eq("Product Title")
      end
    end
  end

  # Task #2: Meta Tag Extraction
  describe "Meta Tag Extraction (Task #2)" do
    it "extracts meta tags by name attribute" do
      WebMock.stub_request(:get, "https://example.com/page")
             .to_return(status: 200, body: valid_html, headers: { "Content-Type" => "text/html" })

      get "/api/v1/data", params: {
        url: "https://example.com/page",
        fields: JSON.generate({
                                "description" => { "selector" => 'meta[name="description"]', "type" => "attribute", "attribute" => "content" },
                                "keywords" => { "selector" => 'meta[name="keywords"]', "type" => "attribute", "attribute" => "content" }
                              })
      }

      expect(response).to have_http_status(:ok)
      data = response.parsed_body
      
      expect(data["description"]).to eq("Test description")
      expect(data["keywords"]).to eq("test, keywords")
    end

    it "extracts OpenGraph meta properties" do
      WebMock.stub_request(:get, "https://example.com/page")
             .to_return(status: 200, body: valid_html, headers: { "Content-Type" => "text/html" })

      get "/api/v1/data", params: {
        url: "https://example.com/page",
        fields: JSON.generate({
                                "og_title" => { "selector" => 'meta[property="og:title"]', "type" => "attribute", "attribute" => "content" }
                              })
      }

      expect(response).to have_http_status(:ok)
      data = response.parsed_body
      
      expect(data["og_title"]).to eq("OpenGraph Title")
    end
  end

  # Task #3: Caching Behavior
  describe "Caching Behavior (Task #3)" do
    it "caches repeated requests to same URL" do
      # First request
      WebMock.stub_request(:get, "https://example.com/cached")
             .to_return(status: 200, body: valid_html, headers: { "Content-Type" => "text/html" })

      get "/api/v1/data", params: {
        url: "https://example.com/cached",
        fields: JSON.generate({ "price" => { "selector" => ".price", "type" => "text" } })
      }

      expect(response).to have_http_status(:ok)
      first_data = response.parsed_body

      # Second request - should use cache (WebMock will verify only one request was made)
      get "/api/v1/data", params: {
        url: "https://example.com/cached",
        fields: JSON.generate({ "price" => { "selector" => ".price", "type" => "text" } })
      }

      expect(response).to have_http_status(:ok)
      second_data = response.parsed_body
      expect(second_data["price"]).to eq(first_data["price"])

      # Verify only one HTTP request was made
      expect(WebMock).to have_requested(:get, "https://example.com/cached").once
    end
  end

  # Security & Error Handling
  describe "Security & Error Handling" do
    context "SSRF Protection" do
      it "blocks requests to localhost" do
        get "/api/v1/data", params: {
          url: "http://localhost:3000/admin",
          fields: JSON.generate({ "title" => { "selector" => "title", "type" => "text" } })
        }

        expect(response).to have_http_status(:bad_request)
        data = response.parsed_body
        expect(data["success"]).to be false
        expect(data["error"]).to include("blocked")
      end

      it "blocks requests to private IP ranges" do
        get "/api/v1/data", params: {
          url: "http://192.168.1.1/internal",
          fields: JSON.generate({ "title" => { "selector" => "title", "type" => "text" } })
        }

        expect(response).to have_http_status(:bad_request)
        data = response.parsed_body
        expect(data["success"]).to be false
        expect(data["error"]).to include("blocked")
      end

      it "blocks requests to 127.0.0.1" do
        get "/api/v1/data", params: {
          url: "http://127.0.0.1:8080/secret",
          fields: JSON.generate({ "title" => { "selector" => "title", "type" => "text" } })
        }

        expect(response).to have_http_status(:bad_request)
        data = response.parsed_body
        expect(data["success"]).to be false
        expect(data["error"]).to include("blocked")
      end
    end

    context "Parameter Validation" do
      it "requires url parameter" do
        get "/api/v1/data", params: {
          fields: JSON.generate({ "title" => { "selector" => "title", "type" => "text" } })
        }

        expect(response).to have_http_status(:bad_request)
        data = response.parsed_body
        expect(data["success"]).to be false
        expect(data["error"]).to include("URL")
      end

      it "requires fields parameter" do
        get "/api/v1/data", params: {
          url: "https://example.com"
        }

        expect(response).to have_http_status(:bad_request)
        data = response.parsed_body
        expect(data["success"]).to be false
        expect(data["error"]).to include("fields")
      end

      it "validates URL format" do
        get "/api/v1/data", params: {
          url: "not-a-valid-url",
          fields: JSON.generate({ "title" => { "selector" => "title", "type" => "text" } })
        }

        expect(response).to have_http_status(:bad_request)
        data = response.parsed_body
        expect(data["success"]).to be false
        expect(data["error"]).to include("URL scheme")
      end

      it "validates JSON fields format" do
        get "/api/v1/data", params: {
          url: "https://example.com",
          fields: "invalid-json"
        }

        expect(response).to have_http_status(:bad_request)
        data = response.parsed_body
        expect(data["success"]).to be false
        expect(data["error"]).to include("Invalid fields")
      end
    end

    context "Network Error Handling" do
      it "handles connection timeouts" do
        WebMock.stub_request(:get, "https://timeout.example.com")
               .to_timeout

        get "/api/v1/data", params: {
          url: "https://timeout.example.com",
          fields: JSON.generate({ "title" => { "selector" => "title", "type" => "text" } })
        }

        expect(response).to have_http_status(:bad_request)
        data = response.parsed_body
        expect(data["success"]).to be false
        expect(data["error"]).to include("timed out")
      end

      it "handles HTTP errors" do
        WebMock.stub_request(:get, "https://error.example.com")
               .to_return(status: 404, body: "Not Found")

        get "/api/v1/data", params: {
          url: "https://error.example.com",
          fields: JSON.generate({ "title" => { "selector" => "title", "type" => "text" } })
        }

        expect(response).to have_http_status(:bad_request)
        data = response.parsed_body
        expect(data["success"]).to be false
        expect(data["error"]).to include("404")
      end
    end

    context "HTML Processing" do
      it "handles malformed HTML gracefully" do
        malformed_html = "<html><head><title>Test</head><body><p>Unclosed paragraph<div>Content</body>"

        WebMock.stub_request(:get, "https://malformed.example.com")
               .to_return(status: 200, body: malformed_html, headers: { "Content-Type" => "text/html" })

        get "/api/v1/data", params: {
          url: "https://malformed.example.com",
          fields: JSON.generate({ "title" => { "selector" => "title", "type" => "text" } })
        }

        expect(response).to have_http_status(:ok)
        data = response.parsed_body
        
        expect(data["title"]).to eq("Test")
      end

      it "handles empty HTML gracefully" do
        WebMock.stub_request(:get, "https://empty.example.com")
               .to_return(status: 200, body: "", headers: { "Content-Type" => "text/html" })

        get "/api/v1/data", params: {
          url: "https://empty.example.com",
          fields: JSON.generate({ "title" => { "selector" => "title", "type" => "text" } })
        }

        expect(response).to have_http_status(:ok)
        data = response.parsed_body
        
        expect(data["title"]).to be_nil
      end

      it "handles selectors that match no elements" do
        WebMock.stub_request(:get, "https://example.com/nomatch")
               .to_return(status: 200, body: valid_html, headers: { "Content-Type" => "text/html" })

        get "/api/v1/data", params: {
          url: "https://example.com/nomatch",
          fields: JSON.generate({ "missing" => { "selector" => ".nonexistent", "type" => "text" } })
        }

        expect(response).to have_http_status(:ok)
        data = response.parsed_body
        
        expect(data["missing"]).to be_nil
      end
    end
  end
end
