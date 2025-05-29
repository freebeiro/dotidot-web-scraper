# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe HttpClientService do
  before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  after do
    WebMock.reset!
  end

  describe ".call" do
    let(:url) { "https://example.com" }
    let(:html_content) { "<html><body><h1>Hello World</h1></body></html>" }

    context "successful requests" do
      before do
        stub_request(:get, url)
          .to_return(status: 200, body: html_content, headers: { "Content-Type" => "text/html" })
      end

      it "returns successful result with content" do
        result = described_class.call(url)

        expect(result[:success]).to be true
        expect(result[:body]).to eq(html_content)
        expect(result[:status]).to eq(200)
        expect(result[:headers]).to include("content-type" => "text/html")
      end

      it "includes request metadata" do
        result = described_class.call(url)

        expect(result[:response_time]).to be_a(Float)
        expect(result[:response_time]).to be >= 0
        expect(result[:attempts]).to eq(1)
      end

      it "follows redirects" do
        stub_request(:get, url)
          .to_return(status: 301, headers: { "Location" => "https://example.com/new" })
        stub_request(:get, "https://example.com/new")
          .to_return(status: 200, body: html_content, headers: { "Content-Type" => "text/html" })

        result = described_class.call(url)

        expect(result[:success]).to be true
        expect(result[:body]).to eq(html_content)
      end

      it "handles multiple redirects" do
        stub_request(:get, url)
          .to_return(status: 301, headers: { "Location" => "https://example.com/step1" })
        stub_request(:get, "https://example.com/step1")
          .to_return(status: 302, headers: { "Location" => "https://example.com/step2" })
        stub_request(:get, "https://example.com/step2")
          .to_return(status: 200, body: html_content)

        result = described_class.call(url)

        expect(result[:success]).to be true
      end
    end

    context "custom headers" do
      it "sends default user agent" do
        stub_request(:get, url)
          .with(headers: { "User-Agent" => "Dotidot-Scraper/1.0" })
          .to_return(status: 200, body: html_content)

        result = described_class.call(url)
        expect(result[:success]).to be true
      end

      it "sends custom user agent when provided" do
        stub_request(:get, url)
          .with(headers: { "User-Agent" => "Custom-Agent/2.0" })
          .to_return(status: 200, body: html_content)

        result = described_class.call(url, user_agent: "Custom-Agent/2.0")
        expect(result[:success]).to be true
      end
    end

    context "timeout handling" do
      it "times out on slow connections" do
        stub_request(:get, url).to_timeout

        result = described_class.call(url, timeout: 1)

        expect(result[:success]).to be false
        expect(result[:error]).to include("timed out")
      end

      it "uses custom timeout value" do
        stub_request(:get, url).to_return(status: 200, body: html_content)

        # Just verify it accepts the timeout parameter
        result = described_class.call(url, timeout: 5)
        expect(result[:success]).to be true
      end

      it "uses default timeout when not specified" do
        stub_request(:get, url).to_timeout

        result = described_class.call(url)

        expect(result[:success]).to be false
        expect(result[:error]).to include("timed out")
      end
    end

    context "retry logic" do
      it "retries on temporary failures" do
        call_count = 0
        stub_request(:get, url)
          .to_return do |_request|
            call_count += 1
            raise HTTP::ConnectionError, "Connection failed" if call_count < 3

            { status: 200, body: html_content }
          end

        result = described_class.call(url)

        expect(result[:success]).to be true
        expect(result[:attempts]).to eq(3)
      end

      it "retries with exponential backoff" do
        start_time = Time.current
        attempts = []

        stub_request(:get, url)
          .to_return do |_request|
            attempts << (Time.current - start_time)
            raise HTTP::TimeoutError if attempts.size < 3

            { status: 200, body: html_content }
          end

        result = described_class.call(url, max_retries: 3)

        expect(result[:success]).to be true
        expect(attempts.size).to eq(3)
        # Second retry should have longer delay than first
        expect(attempts[2] - attempts[1]).to be > (attempts[1] - attempts[0])
      end

      it "does not retry on HTTP errors" do
        call_count = 0
        stub_request(:get, url)
          .to_return do |_request|
            call_count += 1
            { status: 404, body: "Not Found" }
          end

        result = described_class.call(url)

        expect(result[:success]).to be false
        expect(result[:error]).to include("404")
        expect(call_count).to eq(1)
      end

      it "retries on network errors" do
        call_count = 0
        stub_request(:get, url)
          .to_return do |_request|
            call_count += 1
            raise SocketError, "getaddrinfo: Name or service not known" if call_count < 2

            { status: 200, body: html_content }
          end

        result = described_class.call(url)

        expect(result[:success]).to be true
      end

      it "gives up after max retries" do
        stub_request(:get, url)
          .to_raise(HTTP::ConnectionError)

        result = described_class.call(url, max_retries: 2)

        expect(result[:success]).to be false
        expect(result[:error]).to include("Failed after 2 attempts")
        expect(result[:attempts]).to eq(2)
      end
    end

    context "error handling" do
      it "handles connection refused" do
        stub_request(:get, url)
          .to_raise(Errno::ECONNREFUSED)

        result = described_class.call(url)

        expect(result[:success]).to be false
        expect(result[:error]).to include("Connection refused")
      end

      it "handles DNS resolution failures" do
        stub_request(:get, url)
          .to_raise(SocketError.new("getaddrinfo: Name or service not known"))

        result = described_class.call(url)

        expect(result[:success]).to be false
        expect(result[:error]).to include("Name or service not known")
      end

      it "handles SSL errors" do
        stub_request(:get, url)
          .to_raise(OpenSSL::SSL::SSLError.new("SSL_connect returned=1"))

        result = described_class.call(url)

        expect(result[:success]).to be false
        expect(result[:error]).to include("SSL")
      end

      it "handles malformed responses" do
        stub_request(:get, url)
          .to_return(status: 200, body: nil)

        result = described_class.call(url)

        expect(result[:success]).to be true
        expect(result[:body]).to eq("")
      end

      it "handles 4xx errors" do
        stub_request(:get, url)
          .to_return(status: 403, body: "Forbidden")

        result = described_class.call(url)

        expect(result[:success]).to be false
        expect(result[:error]).to include("403")
      end

      it "handles 5xx errors" do
        stub_request(:get, url)
          .to_return(status: 500, body: "Internal Server Error")

        result = described_class.call(url)

        expect(result[:success]).to be false
        expect(result[:error]).to include("500")
      end
    end

    context "content handling" do
      it "handles different encodings" do
        utf8_content = "<html><body>Hello 世界</body></html>"
        stub_request(:get, url)
          .to_return(status: 200, body: utf8_content, headers: { "Content-Type" => "text/html; charset=utf-8" })

        result = described_class.call(url)

        expect(result[:success]).to be true
        expect(result[:body]).to eq(utf8_content)
      end

      it "handles missing content type" do
        stub_request(:get, url)
          .to_return(status: 200, body: html_content, headers: {})

        result = described_class.call(url)

        expect(result[:success]).to be true
        expect(result[:body]).to eq(html_content)
      end
    end

    context "performance" do
      it "tracks response time" do
        stub_request(:get, url)
          .to_return(status: 200, body: html_content)

        result = described_class.call(url)

        expect(result[:response_time]).to be_a(Float)
        expect(result[:response_time]).to be > 0
      end
    end

    context "edge cases" do
      it "handles empty response body" do
        stub_request(:get, url)
          .to_return(status: 200, body: "", headers: { "Content-Type" => "text/html" })

        result = described_class.call(url)

        expect(result[:success]).to be true
        expect(result[:body]).to eq("")
      end

      it "handles very long URLs" do
        long_url = "https://example.com/?#{'param=value&' * 500}"
        stub_request(:get, long_url)
          .to_return(status: 200, body: html_content)

        result = described_class.call(long_url)

        expect(result[:success]).to be true
      end

      it "handles special characters in URLs" do
        special_url = "https://example.com/path?q=hello%20world&foo=bar%2Bbaz"
        stub_request(:get, special_url)
          .to_return(status: 200, body: html_content)

        result = described_class.call(special_url)

        expect(result[:success]).to be true
      end

      it "handles relative redirects" do
        stub_request(:get, url)
          .to_return(status: 302, headers: { "Location" => "/new-path" })
        stub_request(:get, "https://example.com/new-path")
          .to_return(status: 200, body: html_content)

        result = described_class.call(url)

        expect(result[:success]).to be true
      end
    end
  end
end
