# frozen_string_literal: true

require "nokogiri"
require_relative "../../lib/scraper_errors"

# HTML parser service using Nokogiri with error recovery
# Handles malformed HTML gracefully and provides encoding normalization
class HtmlParserService
  # Maximum size for HTML content (10MB)
  MAX_CONTENT_SIZE = 10 * 1024 * 1024

  # Nokogiri parser options for robust HTML parsing
  PARSER_OPTIONS = Nokogiri::XML::ParseOptions::DEFAULT_HTML |
                   Nokogiri::XML::ParseOptions::NOERROR |
                   Nokogiri::XML::ParseOptions::NOWARNING |
                   Nokogiri::XML::ParseOptions::RECOVER

  def self.call(html_content, options = {})
    new(html_content, options).call
  end

  def initialize(html_content, options = {})
    @html_content = html_content
    @encoding = options[:encoding] || "UTF-8"
  end

  def call
    validate_content
    document = parse_html

    {
      success: true,
      doc: document
    }
  rescue ScraperErrors::ValidationError, ScraperErrors::ParsingError => e
    {
      success: false,
      error: e.message
    }
  end

  private

  def validate_content
    raise ScraperErrors::ValidationError, "HTML content cannot be nil" if @html_content.nil?

    # Handle potential encoding issues before any string operations
    begin
      @html_content.valid_encoding?
      content_empty = @html_content.strip.empty?
    rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError, ArgumentError
      # Handle invalid encoding - try to clean it up
      begin
        cleaned_content = @html_content.dup.force_encoding("UTF-8")
                                       .encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
        content_empty = cleaned_content.strip.empty?
        @html_content = cleaned_content # Use cleaned version
      rescue => e
        raise ScraperErrors::ValidationError, "HTML content has invalid encoding: #{e.message}"
      end
    end

    raise ScraperErrors::ValidationError, "HTML content cannot be empty" if content_empty

    return unless @html_content.bytesize > MAX_CONTENT_SIZE

    raise ScraperErrors::ValidationError, "HTML content too large (max #{MAX_CONTENT_SIZE} bytes)"
  end

  def parse_html
    # Parse with Nokogiri's robust HTML parser
    document = Nokogiri::HTML(@html_content, nil, @encoding, PARSER_OPTIONS)

    # Verify we got a valid document
    raise ScraperErrors::ValidationError, "Failed to parse HTML document" if document.nil?

    document
  rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError => e
    Rails.logger.error("Encoding error during HTML parsing: #{e.message}")
    attempt_encoding_recovery
  rescue => e
    Rails.logger.error("Unexpected error during HTML parsing: #{e.message}")
    raise_parsing_error(e)
  end

  def attempt_encoding_recovery
    # Try to parse with forced UTF-8 encoding
    cleaned_content = @html_content.force_encoding("UTF-8")
                                   .encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    Nokogiri::HTML(cleaned_content, nil, "UTF-8", PARSER_OPTIONS)
  rescue => e
    Rails.logger.error("Failed to parse HTML even with encoding recovery: #{e.message}")
    raise_parsing_error(e)
  end

  def raise_parsing_error(error)
    raise ScraperErrors::ValidationError, "HTML parsing failed: #{error.message}"
  end
end
