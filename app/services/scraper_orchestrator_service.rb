# frozen_string_literal: true

require "ostruct"
require "digest"

# Orchestrates the complete web scraping workflow by coordinating URL validation,
# HTTP fetching, HTML parsing, and data extraction services
class ScraperOrchestratorService
  include ScraperHelpers
  def self.call(url:, fields: [])
    new(
      url_validator: UrlValidatorService,
      http_client: HttpClientService,
      html_parser: HtmlParserService,
      css_strategy: CssExtractionStrategy
    ).call(url: url, fields: fields)
  end

  def initialize(url_validator:, http_client:, html_parser:, css_strategy:)
    @url_validator = url_validator
    @http_client = http_client
    @html_parser = html_parser
    @css_strategy = css_strategy
  end

  def call(url:, fields: [])
    @current_url = url
    start_time = Time.current

    log_start_context(url, fields)
    validate_inputs!(url)

    cached_result = check_cache(url, fields)
    return success_response(cached_result, cached: true) if cached_result

    process_scraping_workflow(url, fields, start_time)
  rescue ScraperErrors::BaseError, StandardError => e
    handle_error(e, start_time)
  end

  def process_scraping_workflow(url, fields, start_time)
    html_content = fetch_html(url)
    parsed_document = parse_html(html_content)
    extracted_data = extract_data(parsed_document, fields)

    cache_results(url, fields, extracted_data)
    log_completion(start_time, true, false)
    success_response(extracted_data, cached: false)
  end

  def handle_error(error, start_time)
    log_completion(start_time, false, false, error: error)
    wrapped_error = error.is_a?(ScraperErrors::BaseError) ? error : wrap_unexpected_error(error)
    error_response(wrapped_error)
  end

  private

  attr_reader :url_validator, :http_client, :html_parser, :css_strategy

  def validate_inputs!(url)
    raise ScraperErrors::ValidationError, "URL is required" if url.nil? || url.empty?

    validation_result = url_validator.call(url)
    return if validation_result[:valid]

    raise ScraperErrors::ValidationError, validation_result[:error] || "URL validation failed"
  end

  def check_cache(_url, _fields)
    # Placeholder - will implement caching in a later step
    nil
  end

  def fetch_html(url)
    response = http_client.call(url)

    raise ScraperErrors::NetworkError, response[:error] || "Failed to fetch URL" unless response[:success]

    response[:body].to_s
  rescue HTTP::Error => e
    raise ScraperErrors::NetworkError, "Failed to fetch URL: #{e.message}"
  end

  def parse_html(html_content)
    result = html_parser.call(html_content)

    raise ScraperErrors::ParsingError, result[:error] || "Failed to parse HTML" unless result[:success]

    result[:doc]
  rescue => e
    raise ScraperErrors::ParsingError, "Failed to parse HTML: #{e.message}"
  end

  def extract_data(document, fields)
    return {} if fields.empty?

    # Convert fields hash to array format expected by CSS strategy
    fields_array = fields.is_a?(Hash) ? convert_hash_to_fields_array(fields) : fields

    # Use CSS strategy for all extractions
    result = css_strategy.call(document, fields_array)

    raise ScraperErrors::ExtractionError, result[:error] unless result[:success]

    result[:data]
  end

  def cache_results(_url, _fields, _data)
    # Placeholder - will implement caching in a later step
    true
  end

  def log_completion(start_time, success, cached, error: nil)
    duration = ((Time.current - start_time) * 1000).round(2)
    context = build_completion_context(duration, success, cached, error)
    level = success ? :info : :error
    Rails.logger.public_send(level, "ScraperOrchestrator completed: #{context.to_json}")
  end

  def build_completion_context(duration, success, cached, error)
    context = {
      duration_ms: duration,
      success: success,
      cached: cached,
      url: @current_url,
      request_id: Thread.current[:request_id]
    }

    context.merge!(build_error_context(error)) if error
    context
  end

  def build_error_context(error)
    {
      error_class: error.class.name,
      error_message: error.message
    }
  end
end
