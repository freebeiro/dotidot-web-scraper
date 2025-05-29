# frozen_string_literal: true

# Helper methods for scraper services to reduce complexity in main orchestrator
module ScraperHelpers
  extend ActiveSupport::Concern

  private

  def convert_hash_to_fields_array(fields_hash)
    fields_hash.map do |name, config|
      field_config = config.is_a?(Hash) ? config.dup : { selector: config }
      field_config[:name] = name.to_s
      field_config
    end
  end

  def cache_key(url, fields)
    field_hash = Digest::SHA256.hexdigest(fields.sort.to_json)
    "scraper:#{Digest::SHA256.hexdigest(url)}:#{field_hash}"
  end

  def success_response(data, cached:)
    {
      success: true,
      data: data,
      cached: cached,
      error: nil
    }
  end

  def error_response(error)
    {
      success: false,
      data: nil,
      cached: false,
      error: error.message
    }
  end

  def wrap_unexpected_error(error)
    ScraperErrors::BaseError.new("Unexpected error: #{error.message}")
  end

  def log_start_context(url, fields)
    context = {
      url: url,
      fields_count: fields.size,
      request_id: Thread.current[:request_id]
    }
    Rails.logger.info("ScraperOrchestrator started: #{context.to_json}")
  end

  def extract_meta_tag(document, name)
    meta_tag = document.at_css("meta[name='#{name}'], meta[property='#{name}']")
    meta_tag&.attribute("content")&.value
  end
end
