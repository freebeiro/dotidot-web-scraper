# frozen_string_literal: true

require "ostruct"
require "digest"

# Orchestrates the complete web scraping workflow by coordinating URL validation,
# HTTP fetching, HTML parsing, and data extraction services
class ScraperOrchestratorService
  include ScraperHelpers
  include MetaFieldHandler
  def self.call(url:, fields: [])
    new(
      url_validator: UrlValidatorService,
      http_client: HttpClientService,
      html_parser: HtmlParserService,
      css_strategy: CssExtractionStrategy,
      meta_strategy: MetaExtractionStrategy
    ).call(url: url, fields: fields)
  end

  def initialize(url_validator:, http_client:, html_parser:, css_strategy:, meta_strategy:)
    @url_validator = url_validator
    @http_client = http_client
    @html_parser = html_parser
    @css_strategy = css_strategy
    @meta_strategy = meta_strategy
  end

  def call(url:, fields: [])
    @current_url = url
    start_time = Time.current

    log_start_context(url, fields)
    validate_inputs!(url)

    cached_result = check_cache(url, fields)
    return cached_result if cached_result

    process_scraping_workflow(url, fields, start_time)
  rescue ScraperErrors::BaseError, StandardError => e
    handle_error(e, start_time)
  end

  def process_scraping_workflow(url, fields, start_time)
    html_content = fetch_html(url)
    parsed_document = parse_html(html_content)
    extracted_data = extract_data(parsed_document, fields)

    response_data = success_response(extracted_data, cached: false)
    cache_results(url, fields, response_data)
    log_completion(start_time, true, false)
    response_data
  end

  def handle_error(error, start_time)
    log_completion(start_time, false, false, error: error)
    wrapped_error = error.is_a?(ScraperErrors::BaseError) ? error : wrap_unexpected_error(error)
    error_response(wrapped_error)
  end

  private

  attr_reader :url_validator, :http_client, :html_parser, :css_strategy, :meta_strategy

  def validate_inputs!(url)
    raise ScraperErrors::ValidationError, "URL is required" if url.nil? || url.empty?

    validation_result = url_validator.call(url)
    return if validation_result[:valid]

    raise ScraperErrors::ValidationError, validation_result[:error] || "URL validation failed"
  end

  def check_cache(url, fields)
    cached_data = CacheService.get(url: url, fields: fields)

    cached_data.merge(cached: true) if cached_data.is_a?(Hash) && cached_data[:success]
  rescue => e
    Rails.logger.warn("Cache check failed: #{e.message}")
    nil # Return nil to proceed with fresh scraping if cache fails
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
    return {} if fields.nil? || (fields.respond_to?(:empty?) && fields.empty?)

    # Convert fields hash to array format if needed
    fields_array = if fields.is_a?(Hash)
                     convert_hash_to_fields_array(fields)
                   elsif fields.is_a?(Array)
                     fields
                   else
                     raise ScraperErrors::ValidationError, "Invalid fields format: expected Hash or Array"
                   end

    # Separate CSS selector fields from meta tag fields
    css_fields, meta_fields = partition_fields(fields_array)

    # Extract data using appropriate strategies
    data = {}

    # Extract CSS selector fields
    if css_fields.any?
      css_result = css_strategy.call(document, css_fields)
      raise ScraperErrors::ExtractionError, css_result[:error] unless css_result[:success]

      data.merge!(css_result[:data])
    end

    # Extract meta tag fields
    if meta_fields.any?
      meta_result = meta_strategy.call(document, meta_fields)
      raise ScraperErrors::ExtractionError, meta_result[:error] unless meta_result[:success]

      data.merge!(meta_result[:data])
    end

    data
  end

  def cache_results(url, fields, data)
    # Only cache successful results
    return false unless data.is_a?(Hash) && data[:success]

    # Store the data with cached: false to indicate it's fresh
    cache_data = data.merge(cached: false)

    CacheService.set(url: url, fields: fields, data: cache_data)
  rescue => e
    Rails.logger.warn("Cache storage failed: #{e.message}")
    false
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
