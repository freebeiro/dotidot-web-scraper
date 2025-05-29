# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Data meta tag extraction", type: :request do
  let(:example_html) do
    <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="description" content="A great page description">
          <meta name="keywords" content="test, example, meta">
          <meta property="og:title" content="Example OG Title">
          <meta property="og:description" content="Example OG Description">
          <meta property="og:image" content="https://example.com/image.jpg">
          <meta http-equiv="content-type" content="text/html; charset=UTF-8">
          <title>Example Page</title>
        </head>
        <body>
          <h1>Example Domain</h1>
          <p>This domain is for use in illustrative examples.</p>
        </body>
      </html>
    HTML
  end

  before do
    stub_request(:get, "https://example.com")
      .to_return(status: 200, body: example_html, headers: { "Content-Type" => "text/html" })
  end

  describe "GET /api/v1/data" do
    context "with meta tag fields using type: meta" do
      let(:fields) do
        [
          { "name" => "description", "type" => "meta" },
          { "name" => "keywords", "type" => "meta" },
          { "name" => "og:title", "type" => "meta" }
        ]
      end

      it "extracts meta tag content" do
        get "/api/v1/data", params: {
          url: "https://example.com",
          fields: fields.to_json
        }

        if response.status != 200
          puts "Response status: #{response.status}"
          puts "Response body: #{response.body}"
        end

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({
                                             "description" => "A great page description",
                                             "keywords" => "test, example, meta",
                                             "og:title" => "Example OG Title"
                                           })
      end
    end

    context "with meta tag fields using meta: prefix convention" do
      let(:fields) do
        [
          { "name" => "meta:description" },
          { "name" => "meta:og:title" },
          { "name" => "meta:og:image" }
        ]
      end

      it "extracts meta tags and preserves meta: prefix in response" do
        get "/api/v1/data", params: {
          url: "https://example.com",
          fields: fields.to_json
        }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({
                                             "meta:description" => "A great page description",
                                             "meta:og:title" => "Example OG Title",
                                             "meta:og:image" => "https://example.com/image.jpg"
                                           })
      end
    end

    context "with mixed CSS selectors and meta tags" do
      let(:fields) do
        [
          { "name" => "title", "selector" => "title" },
          { "name" => "heading", "selector" => "h1" },
          { "name" => "description", "type" => "meta" },
          { "name" => "meta:og:title" }
        ]
      end

      it "extracts both CSS and meta fields" do
        get "/api/v1/data", params: {
          url: "https://example.com",
          fields: fields.to_json
        }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({
                                             "title" => "Example Page",
                                             "heading" => "Example Domain",
                                             "description" => "A great page description",
                                             "meta:og:title" => "Example OG Title"
                                           })
      end
    end

    context "with missing meta tags" do
      let(:fields) do
        [
          { "name" => "description", "type" => "meta" },
          { "name" => "author", "type" => "meta" },
          { "name" => "nonexistent", "type" => "meta" }
        ]
      end

      it "returns only existing meta tags" do
        get "/api/v1/data", params: {
          url: "https://example.com",
          fields: fields.to_json
        }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({
                                             "description" => "A great page description"
                                           })
      end
    end
  end

  describe "POST /api/v1/data" do
    context "with meta tag extraction" do
      let(:params) do
        {
          url: "https://example.com",
          fields: [
            { "name" => "title", "selector" => "title" },
            { "name" => "description", "type" => "meta" },
            { "name" => "meta:og:description" },
            { "name" => "meta:og:image" }
          ]
        }
      end

      it "handles POST request with meta fields" do
        post "/api/v1/data", params: params.to_json,
                             headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({
                                             "title" => "Example Page",
                                             "description" => "A great page description",
                                             "meta:og:description" => "Example OG Description",
                                             "meta:og:image" => "https://example.com/image.jpg"
                                           })
      end
    end
  end

  context "with http-equiv meta tags" do
    let(:fields) do
      [
        { "name" => "content-type", "type" => "meta" }
      ]
    end

    it "extracts http-equiv meta tags" do
      get "/api/v1/data", params: {
        url: "https://example.com",
        fields: fields.to_json
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq({
                                           "content-type" => "text/html; charset=UTF-8"
                                         })
    end
  end

  context "with case-insensitive meta tag matching" do
    let(:case_html) do
      <<~HTML
        <html>
          <head>
            <meta name="DESCRIPTION" content="Uppercase name">
            <meta name="Keywords" content="Mixed case">
          </head>
        </html>
      HTML
    end

    before do
      stub_request(:get, "https://case-example.com")
        .to_return(status: 200, body: case_html, headers: { "Content-Type" => "text/html" })
    end

    let(:fields) do
      [
        { "name" => "description", "type" => "meta" },
        { "name" => "keywords", "type" => "meta" }
      ]
    end

    it "matches meta tags case-insensitively" do
      get "/api/v1/data", params: {
        url: "https://case-example.com",
        fields: fields.to_json
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq({
                                           "description" => "Uppercase name",
                                           "keywords" => "Mixed case"
                                         })
    end
  end
end
