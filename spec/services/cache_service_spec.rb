# frozen_string_literal: true

require "rails_helper"

RSpec.describe CacheService, type: :service do
  let(:url) { "https://example.com" }
  let(:fields) { [{ "name" => "title", "selector" => "h1" }] }
  let(:data) { { success: true, data: { "title" => "Test Title" } } }

  describe ".call" do
    context "when cache is empty" do
      it "executes the block and caches the result" do
        expect(Rails.cache).to receive(:read).and_return(nil)
        expect(Rails.cache).to receive(:write).with(kind_of(String), data.merge(cached: false), expires_in: CacheService::DEFAULT_TTL)

        result = described_class.call(url: url, fields: fields) do
          data
        end

        expect(result).to eq(data.merge(cached: false))
      end
    end

    context "when data exists in cache" do
      let(:cached_data) { data.merge(cached: false) }

      it "returns cached data with cached flag set to true" do
        expect(Rails.cache).to receive(:read).and_return(cached_data)

        result = described_class.call(url: url, fields: fields) do
          data
        end

        expect(result).to eq(cached_data.merge(cached: true))
      end
    end

    context "when cache operation fails" do
      it "falls back to executing the block" do
        allow(Rails.cache).to receive(:read).and_raise(Redis::ConnectionError.new("Connection failed"))

        result = described_class.call(url: url, fields: fields) do
          data
        end

        expect(result).to eq(data.merge(cached: false))
      end
    end

    context "when no block is given and cache fails" do
      it "returns nil" do
        allow(Rails.cache).to receive(:read).and_raise(Redis::ConnectionError.new("Connection failed"))

        result = described_class.call(url: url, fields: fields)

        expect(result).to be_nil
      end
    end
  end

  describe ".get" do
    context "when data exists in cache" do
      it "returns the cached data" do
        expect(Rails.cache).to receive(:read).and_return(data)

        result = described_class.get(url: url, fields: fields)

        expect(result).to eq(data)
      end
    end

    context "when cache is empty" do
      it "returns nil" do
        expect(Rails.cache).to receive(:read).and_return(nil)

        result = described_class.get(url: url, fields: fields)

        expect(result).to be_nil
      end
    end

    context "when cache read fails" do
      it "returns nil and logs warning" do
        allow(Rails.cache).to receive(:read).and_raise(Redis::ConnectionError.new("Connection failed"))
        expect(Rails.logger).to receive(:warn).with(/Cache read failed/)

        result = described_class.get(url: url, fields: fields)

        expect(result).to be_nil
      end
    end
  end

  describe ".set" do
    context "when cache write succeeds" do
      it "stores data in cache" do
        expect(Rails.cache).to receive(:write).with(
          kind_of(String),
          data,
          expires_in: CacheService::DEFAULT_TTL
        ).and_return(true)

        result = described_class.set(url: url, fields: fields, data: data)

        expect(result).to be_truthy
      end
    end

    context "when cache write fails" do
      it "returns false and logs warning" do
        allow(Rails.cache).to receive(:write).and_raise(Redis::ConnectionError.new("Connection failed"))
        expect(Rails.logger).to receive(:warn).with(/Cache write failed/)

        result = described_class.set(url: url, fields: fields, data: data)

        expect(result).to be false
      end
    end

    context "with custom TTL" do
      it "uses the provided TTL" do
        custom_ttl = 30.minutes

        expect(Rails.cache).to receive(:write).with(
          kind_of(String),
          data,
          expires_in: custom_ttl
        ).and_return(true)

        described_class.set(url: url, fields: fields, data: data, ttl: custom_ttl)
      end
    end
  end

  describe ".invalidate" do
    context "when cache delete succeeds" do
      it "removes data from cache" do
        expect(Rails.cache).to receive(:delete).and_return(true)

        result = described_class.invalidate(url: url, fields: fields)

        expect(result).to be_truthy
      end
    end

    context "when cache delete fails" do
      it "returns false and logs warning" do
        allow(Rails.cache).to receive(:delete).and_raise(Redis::ConnectionError.new("Connection failed"))
        expect(Rails.logger).to receive(:warn).with(/Cache invalidation failed/)

        result = described_class.invalidate(url: url, fields: fields)

        expect(result).to be false
      end
    end
  end

  describe "cache key generation" do
    let(:service) { described_class.new }

    context "with different URLs" do
      it "generates different cache keys" do
        key1 = service.send(:generate_cache_key, "https://example.com", fields)
        key2 = service.send(:generate_cache_key, "https://test.com", fields)

        expect(key1).not_to eq(key2)
      end
    end

    context "with different fields" do
      it "generates different cache keys" do
        fields1 = [{ "name" => "title", "selector" => "h1" }]
        fields2 = [{ "name" => "description", "selector" => "p" }]

        key1 = service.send(:generate_cache_key, url, fields1)
        key2 = service.send(:generate_cache_key, url, fields2)

        expect(key1).not_to eq(key2)
      end
    end

    context "with same URL and fields" do
      it "generates consistent cache keys" do
        key1 = service.send(:generate_cache_key, url, fields)
        key2 = service.send(:generate_cache_key, url, fields)

        expect(key1).to eq(key2)
      end
    end

    context "with different field order" do
      it "generates the same cache key (normalized)" do
        fields1 = [
          { "name" => "title", "selector" => "h1" },
          { "name" => "description", "selector" => "p" }
        ]
        fields2 = [
          { "name" => "description", "selector" => "p" },
          { "name" => "title", "selector" => "h1" }
        ]

        key1 = service.send(:generate_cache_key, url, fields1)
        key2 = service.send(:generate_cache_key, url, fields2)

        expect(key1).to eq(key2)
      end
    end
  end
end
