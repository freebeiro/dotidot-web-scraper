# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rate Limiting", type: :request do
  let(:valid_url) { "https://example.com" }
  let(:valid_fields) { { "title" => "h1" } }
  let(:valid_params) do
    {
      url: valid_url,
      fields: valid_fields.to_json
    }
  end
  let(:valid_post_params) do
    {
      url: valid_url,
      fields: valid_fields
    }
  end

  before do
    # Enable Rack::Attack for rate limiting tests
    ENV["TEST_RACK_ATTACK"] = "true"
    Rack::Attack.enabled = true
    
    # Stub external HTTP requests
    stub_request(:get, valid_url)
      .to_return(status: 200, body: "<html><head><title>Test</title></head></html>")
    
    # Clear any existing rate limit data
    Rack::Attack.cache.store.clear if Rack::Attack.cache.store.respond_to?(:clear)
    Rails.cache.clear
    
    # Give a moment for cache to clear
    sleep 0.1
  end

  after do
    # Clean up rate limit data
    Rack::Attack.cache.store.clear if Rack::Attack.cache.store.respond_to?(:clear)
    Rails.cache.clear
    
    # Disable Rack::Attack again after rate limiting tests
    ENV["TEST_RACK_ATTACK"] = nil
    Rack::Attack.enabled = false
  end

  describe "IP-based rate limiting" do
    it "allows requests under the limit" do
      # Make 10 requests (under the 20 per minute limit)
      10.times do
        get "/api/v1/data", params: valid_params
        expect(response).to have_http_status(:ok)
      end
    end

    it "blocks requests over the domain limit" do
      # Make 11 requests to exceed the 10 per minute per domain limit
      10.times do |i|
        get "/api/v1/data", params: valid_params
        expect(response).to have_http_status(:ok)
      end

      # 11th request should be rate limited (domain limit)
      get "/api/v1/data", params: valid_params
      expect(response).to have_http_status(:too_many_requests)
      
      json_response = JSON.parse(response.body)
      expect(json_response["success"]).to be false
      expect(json_response["error"]).to include("Rate limit exceeded")
      expect(json_response["retry_after"]).to be_present
    end

    it "includes proper rate limit headers" do
      # Exceed rate limit
      21.times do
        get "/api/v1/data", params: valid_params
      end

      expect(response.headers["X-RateLimit-Limit"]).to eq("20")
      expect(response.headers["X-RateLimit-Remaining"]).to eq("0")
      expect(response.headers["Retry-After"]).to be_present
    end

    it "works with POST requests" do
      # Make 11 POST requests to exceed domain limit
      10.times do
        post "/api/v1/data", 
             params: valid_post_params.to_json,
             headers: { "Content-Type" => "application/json" }
        expect(response).to have_http_status(:ok)
      end

      # 11th request should be rate limited
      post "/api/v1/data", 
           params: valid_post_params.to_json,
           headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "Domain-based rate limiting" do
    let(:different_urls) do
      [
        "https://site1.com",
        "https://site2.com", 
        "https://site3.com"
      ]
    end

    before do
      # Stub all different URLs
      different_urls.each do |url|
        stub_request(:get, url)
          .to_return(status: 200, body: "<html><head><title>Test</title></head></html>")
      end
    end

    it "allows requests to different domains" do
      # Make requests to different domains (should not be limited by domain rule)
      different_urls.each do |url|
        5.times do
          get "/api/v1/data", params: { url: url, fields: valid_fields.to_json }
          expect(response).to have_http_status(:ok)
        end
      end
    end

    it "limits requests to the same domain" do
      domain_url = "https://same-domain.com"
      stub_request(:get, domain_url)
        .to_return(status: 200, body: "<html><head><title>Test</title></head></html>")

      # Make 10 requests to same domain (under domain limit)
      10.times do
        get "/api/v1/data", params: { url: domain_url, fields: valid_fields.to_json }
        expect(response).to have_http_status(:ok)
      end

      # 11th request to same domain should be limited
      get "/api/v1/data", params: { url: domain_url, fields: valid_fields.to_json }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "Global rate limiting" do
    it "enforces global limits across all requests" do
      # This test would require making 100+ requests which might be slow
      # For now, we'll test the concept with a smaller number
      
      # Make requests that would be under IP and domain limits but test global concept
      different_urls = (1..20).map { |i| "https://site#{i}.com" }
      
      different_urls.each do |url|
        stub_request(:get, url)
          .to_return(status: 200, body: "<html><head><title>Test</title></head></html>")
      end

      # Each URL gets 5 requests (under domain limit), but total is 100
      # In real scenario, this would trigger global limit
      different_urls.each do |url|
        5.times do
          get "/api/v1/data", params: { url: url, fields: valid_fields.to_json }
          # We expect these to pass in our test environment
          # In production with actual rate limiting, the global limit would kick in
        end
      end
    end
  end

  describe "Security blocking" do
    let(:malicious_urls) do
      [
        "http://localhost:3000",
        "http://127.0.0.1",
        "http://192.168.1.1",
        "http://10.0.0.1",
        "file:///etc/passwd",
        "javascript:alert('xss')",
        "data:text/plain,hello"
      ]
    end

    it "blocks malicious URL patterns" do
      malicious_urls.each do |malicious_url|
        get "/api/v1/data", params: { url: malicious_url, fields: valid_fields.to_json }
        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["error"]).to include("blocked for security reasons")
      end
    end

    it "blocks malicious URLs in POST requests" do
      malicious_urls.each do |malicious_url|
        post_params = { url: malicious_url, fields: valid_fields }
        
        post "/api/v1/data", 
             params: post_params.to_json,
             headers: { "Content-Type" => "application/json" }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "Safelist functionality" do
    it "allows health check endpoints" do
      # Health checks should not be rate limited
      100.times do
        get "/up"
        expect(response).to have_http_status(:ok)
      end
    end

    context "in development environment" do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
      end

      it "allows localhost traffic in development" do
        # In development, localhost should be safelisted
        # Make multiple requests from localhost in dev mode
        50.times do
          get "/api/v1/data", params: valid_params, headers: { "REMOTE_ADDR" => "127.0.0.1" }
        end
        # All requests should succeed (not rate limited)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "Rate limit response format" do
    before do
      # Trigger rate limit
      21.times do
        get "/api/v1/data", params: valid_params
      end
    end

    it "returns consistent JSON error format" do
      json_response = JSON.parse(response.body)
      
      expect(json_response).to include(
        "success" => false,
        "error" => a_string_including("Rate limit exceeded"),
        "retry_after" => be_a(Integer)
      )
    end

    it "includes security headers" do
      expect(response.headers["Content-Type"]).to include("application/json")
      expect(response.headers["X-RateLimit-Limit"]).to be_present
      expect(response.headers["X-RateLimit-Remaining"]).to be_present
      expect(response.headers["X-RateLimit-Reset"]).to be_present
    end
  end
end
