# frozen_string_literal: true

require_relative "../../lib/scraper_errors"

# CSS selector-based data extraction strategy
# Extracts data from HTML documents using CSS selectors with error handling
class CssExtractionStrategy
  # Structure for extraction results
  ExtractedField = Struct.new(:selector, :value, :error, keyword_init: true) do
    def success?
      error.nil?
    end

    def failed?
      !success?
    end
  end

  # Maximum allowed selector length to prevent abuse
  MAX_SELECTOR_LENGTH = 1000

  # Patterns that could indicate malicious selectors
  SUSPICIOUS_PATTERNS = [
    /javascript:/i,
    /data:/i,
    /vbscript:/i
  ].freeze

  def self.call(document, fields)
    new(document, fields).call
  end

  def initialize(document, fields)
    @document = document
    @fields = normalize_fields(fields)
  end

  def call
    validate_inputs

    results = @fields.map do |field|
      extract_single_field(field)
    rescue => e
      Rails.logger.error("Error extracting field '#{field[:selector]}': #{e.message}")
      ExtractedField.new(
        selector: field[:selector],
        value: nil,
        error: e.message
      )
    end

    # Convert to hash format expected by tests
    data = {}
    results.each do |result|
      next unless result.success?

      # Extract field name from selector or use index
      field_name = @fields.find { |f| f[:selector] == result.selector }&.dig(:name) || result.selector
      data[field_name] = result.value
    end

    {
      success: true,
      data: data,
      results: results
    }
  rescue => e
    {
      success: false,
      error: e.message
    }
  end

  private

  def normalize_fields(fields)
    return [] if fields.nil?

    Array(fields).map do |field|
      case field
      when String
        { selector: field, name: field }
      when Hash
        field = field.stringify_keys if field.respond_to?(:stringify_keys)
        {
          selector: field["selector"] || field[:selector],
          name: field["name"] || field[:name] || field["selector"] || field[:selector]
        }
      else
        raise ScraperErrors::ValidationError, "Invalid field format: #{field.class}"
      end
    end
  end

  def validate_inputs
    raise ScraperErrors::ValidationError, "Document cannot be nil" if @document.nil?
    raise ScraperErrors::ValidationError, "Fields cannot be empty" if @fields.empty?

    @fields.each do |field|
      validate_selector(field[:selector])
    end
  end

  def validate_selector(selector)
    raise ScraperErrors::ValidationError, "Selector cannot be nil" if selector.nil?
    raise ScraperErrors::ValidationError, "Selector cannot be empty" if selector.strip.empty?

    if selector.length > MAX_SELECTOR_LENGTH
      raise ScraperErrors::ValidationError, "Selector too long (max #{MAX_SELECTOR_LENGTH} characters)"
    end

    return unless SUSPICIOUS_PATTERNS.any? { |pattern| selector.match?(pattern) }

    raise ScraperErrors::SecurityError, "Potentially malicious selector detected"
  end

  def extract_single_field(field)
    selector = field[:selector]

    begin
      elements = @document.css(selector)
      value = extract_value_from_elements(elements)

      ExtractedField.new(
        selector: selector,
        value: value,
        error: nil
      )
    rescue Nokogiri::CSS::SyntaxError => e
      raise ScraperErrors::ValidationError, "Invalid CSS selector '#{selector}': #{e.message}"
    end
  end

  def extract_value_from_elements(elements)
    return nil if elements.empty?

    if elements.length == 1
      clean_text(elements.first.text)
    else
      # Multiple elements - return array of text content
      elements.map { |element| clean_text(element.text) }
    end
  end

  def clean_text(text)
    return "" if text.nil?

    # Clean up whitespace and normalize
    text.to_s
        .strip
        .gsub(/\s+/, " ") # Normalize internal whitespace
        .tr("\u00A0", " ") # Replace non-breaking spaces
        .strip
  end
end
