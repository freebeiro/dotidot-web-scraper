# frozen_string_literal: true

require "rails_helper"

RSpec.describe UrlValidatorService do
  describe ".call" do
    context "with valid URLs" do
      it "validates standard HTTP URL" do
        result = described_class.call("http://example.com")
        expect(result[:valid]).to be true
        expect(result[:url]).to eq("http://example.com")
      end

      it "validates HTTPS URL" do
        result = described_class.call("https://example.com")
        expect(result[:valid]).to be true
        expect(result[:url]).to eq("https://example.com")
      end

      it "validates URL with path" do
        result = described_class.call("https://example.com/path/to/resource")
        expect(result[:valid]).to be true
      end

      it "validates URL with query parameters" do
        result = described_class.call("https://example.com?param=value&other=123")
        expect(result[:valid]).to be true
      end

      it "validates URL with fragment" do
        result = described_class.call("https://example.com#section")
        expect(result[:valid]).to be true
      end

      it "validates URL with port" do
        result = described_class.call("https://example.com:8080")
        expect(result[:valid]).to be true
      end

      it "rejects URLs without scheme" do
        result = described_class.call("example.com")
        expect(result[:valid]).to be false
        expect(result[:error]).to include("URL scheme '' not allowed")
      end

      it "handles URLs with authentication" do
        result = described_class.call("https://user:pass@example.com")
        expect(result[:valid]).to be true
      end
    end

    context "with invalid URLs" do
      it "rejects empty URL" do
        result = described_class.call("")
        expect(result[:valid]).to be false
        expect(result[:error]).to include("URL cannot be blank")
      end

      it "rejects nil URL" do
        result = described_class.call(nil)
        expect(result[:valid]).to be false
        expect(result[:error]).to include("URL cannot be blank")
      end

      it "rejects malformed URLs" do
        result = described_class.call("not a url")
        expect(result[:valid]).to be false
        expect(result[:error]).to include("Invalid URL format")
      end

      it "rejects URLs with invalid schemes" do
        result = described_class.call("ftp://example.com")
        expect(result[:valid]).to be false
        expect(result[:error]).to include("URL scheme 'ftp' not allowed")
      end

      it "rejects javascript URLs" do
        result = described_class.call("javascript:alert('xss')")
        expect(result[:valid]).to be false
        expect(result[:error]).to include("URL scheme 'javascript' not allowed")
      end

      it "rejects data URLs" do
        result = described_class.call("data:text/plain,hello")
        expect(result[:valid]).to be false
        expect(result[:error]).to include("URL scheme 'data' not allowed")
      end

      it "rejects URLs that are too long" do
        long_url = "https://example.com/" + "a" * 2100
        result = described_class.call(long_url)
        expect(result[:valid]).to be false
        expect(result[:error]).to include("URL too long")
      end

      it "rejects URLs with control characters" do
        result = described_class.call("https://example.com/\x00test")
        expect(result[:valid]).to be false
        expect(result[:error]).to include("Invalid URL format")
      end
    end

    context "SSRF protection" do
      it "blocks localhost" do
        result = described_class.call("http://localhost")
        expect(result[:valid]).to be false
        expect(result[:error]).to include("Access to host 'localhost' is blocked")
      end

      it "blocks 127.0.0.1" do
        result = described_class.call("http://127.0.0.1")
        expect(result[:valid]).to be false
        expect(result[:error]).to include("Access to host '127.0.0.1' is blocked")
      end

      it "blocks 0.0.0.0" do
        result = described_class.call("http://0.0.0.0")
        expect(result[:valid]).to be false
        expect(result[:error]).to include("Access to host '0.0.0.0' is blocked")
      end

      it "blocks metadata service endpoints" do
        result = described_class.call("http://169.254.169.254")
        expect(result[:valid]).to be false
        expect(result[:error]).to include("Access to host '169.254.169.254' is blocked")
      end

      context "private IP ranges" do
        it "blocks private Class A addresses" do
          result = described_class.call("http://10.0.0.1")
          expect(result[:valid]).to be false
          expect(result[:error]).to include("Access to private IP address")
        end

        it "blocks private Class B addresses" do
          result = described_class.call("http://172.16.0.1")
          expect(result[:valid]).to be false
          expect(result[:error]).to include("Access to private IP address")
        end

        it "blocks private Class C addresses" do
          result = described_class.call("http://192.168.1.1")
          expect(result[:valid]).to be false
          expect(result[:error]).to include("Access to private IP address")
        end

        it "blocks link-local addresses" do
          result = described_class.call("http://169.254.1.1")
          expect(result[:valid]).to be false
          expect(result[:error]).to include("Access to private IP address")
        end

        it "allows public IP addresses" do
          result = described_class.call("http://8.8.8.8")
          expect(result[:valid]).to be true
        end

        it "allows public domain names" do
          result = described_class.call("https://example.com")
          expect(result[:valid]).to be true
        end
      end

      context "private IPv6 ranges" do
        it "blocks IPv6 loopback" do
          result = described_class.call("http://[::1]")
          expect(result[:valid]).to be false
          expect(result[:error]).to include("Access to private IP address")
        end

        it "blocks IPv6 unique local addresses" do
          result = described_class.call("http://[fc00::1]")
          expect(result[:valid]).to be false
          expect(result[:error]).to include("Access to private IP address")
        end

        it "blocks IPv6 link-local addresses" do
          result = described_class.call("http://[fe80::1]")
          expect(result[:valid]).to be false
          expect(result[:error]).to include("Access to private IP address")
        end
      end
    end

    context "edge cases" do
      it "handles URLs with multiple consecutive slashes" do
        result = described_class.call("https://example.com//path//to///resource")
        expect(result[:valid]).to be true
      end

      it "handles URLs with special characters" do
        result = described_class.call("https://example.com/path?q=hello%20world")
        expect(result[:valid]).to be true
      end

      it "preserves query parameters" do
        url = "https://example.com/search?q=test&page=2"
        result = described_class.call(url)
        expect(result[:valid]).to be true
        expect(result[:url]).to eq(url)
      end

      it "preserves existing scheme" do
        http_url = "http://example.com"
        result = described_class.call(http_url)
        expect(result[:valid]).to be true
        expect(result[:url]).to eq(http_url)

        https_url = "https://example.com"
        result = described_class.call(https_url)
        expect(result[:valid]).to be true
        expect(result[:url]).to eq(https_url)
      end

      it "handles trailing slashes" do
        result = described_class.call("https://example.com/")
        expect(result[:valid]).to be true
      end
    end

    context "performance" do
      it "validates URLs quickly" do
        start_time = Time.current
        1000.times do
          described_class.call("https://example.com")
        end
        end_time = Time.current

        expect(end_time - start_time).to be < 1.0
      end
    end
  end
end