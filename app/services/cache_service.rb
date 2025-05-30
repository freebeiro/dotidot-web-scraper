# frozen_string_literal: true

require "digest"

# Cache service for web scraper results
# Provides get_or_set functionality with SHA256 cache key generation
class CacheService
  # Default TTL for cached scraper results
  DEFAULT_TTL = 1.hour

  def self.call(url:, fields:, &)
    new.call(url: url, fields: fields, &)
  end

  def call(url:, fields:, &)
    cache_key = generate_cache_key(url, fields)
    cached_data = Rails.cache.read(cache_key)

    return format_cached_response(cached_data) if cached_data
    return nil unless block_given?

    execute_and_cache(cache_key, &)
  rescue => e
    Rails.logger.warn("Cache operation failed: #{e.message}")
    execute_with_fallback(&) if block_given?
  end

  def self.invalidate(url:, fields:)
    new.invalidate(url: url, fields: fields)
  end

  def invalidate(url:, fields:)
    cache_key = generate_cache_key(url, fields)
    Rails.cache.delete(cache_key)
  rescue => e
    Rails.logger.warn("Cache invalidation failed: #{e.message}")
    false
  end

  def self.get(url:, fields:)
    new.get(url: url, fields: fields)
  end

  def get(url:, fields:)
    cache_key = generate_cache_key(url, fields)
    Rails.cache.read(cache_key)
  rescue => e
    Rails.logger.warn("Cache read failed: #{e.message}")
    nil
  end

  def self.set(url:, fields:, data:, ttl: DEFAULT_TTL)
    new.set(url: url, fields: fields, data: data, ttl: ttl)
  end

  def set(url:, fields:, data:, ttl: DEFAULT_TTL)
    cache_key = generate_cache_key(url, fields)
    Rails.cache.write(cache_key, data, expires_in: ttl)
  rescue => e
    Rails.logger.warn("Cache write failed: #{e.message}")
    false
  end

  private

  def format_cached_response(data)
    return data unless data.is_a?(Hash) && data.key?(:success)

    data.merge(cached: true)
  end

  def execute_and_cache(cache_key, &block)
    result = block.call
    cache_data = format_fresh_response(result)
    Rails.cache.write(cache_key, cache_data, expires_in: DEFAULT_TTL)
    cache_data
  end

  def format_fresh_response(result)
    return result unless result.is_a?(Hash) && result.key?(:success)

    result.merge(cached: false)
  end

  def execute_with_fallback(&block)
    result = block.call
    format_fresh_response(result)
  end

  def generate_cache_key(url, fields)
    # Create a stable hash of the URL and fields for cache key
    content = {
      url: url,
      fields: normalize_fields_for_cache(fields)
    }.to_json

    "scraper_result:#{Digest::SHA256.hexdigest(content)}"
  end

  def normalize_fields_for_cache(fields)
    # Normalize fields to ensure consistent cache keys
    case fields
    when Array
      fields.map { |field| normalize_field(field) }.sort_by(&:to_s)
    when Hash
      fields.transform_values { |value| normalize_field(value) }.sort.to_h
    else
      fields
    end
  end

  def normalize_field(field)
    case field
    when Hash
      field.sort.to_h
    when String
      field
    else
      field.to_s
    end
  end
end
