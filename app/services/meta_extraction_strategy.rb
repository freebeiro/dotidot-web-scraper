# frozen_string_literal: true

require_relative "../../lib/scraper_errors"
require_relative "concerns/extracted_field"

# Meta tag extraction strategy
# Extracts meta tag content from HTML documents with support for name, property, and http-equiv attributes
class MetaExtractionStrategy
  include ExtractedField

  # Common meta tag attributes we support
  META_ATTRIBUTES = %w[name property http-equiv].freeze

  def self.call(document, fields)
    new(document, fields).call
  rescue => e
    {
      success: false,
      error: e.message
    }
  end

  def initialize(document, fields)
    @document = document
    @fields = normalize_fields(fields)
  end

  def call
    begin
      validate_inputs
    rescue => e
      return {
        success: false,
        error: e.message
      }
    end

    results = @fields.map do |field|
      extract_meta_tag(field)
    rescue => e
      field_name = field.is_a?(Hash) ? field[:name] : field
      Rails.logger.error("Error extracting meta tag '#{field_name}': #{e.message}")
      ExtractedField.new(
        selector: field_name,
        value: nil,
        error: e.message
      )
    end

    # Convert to hash format consistent with CSS strategy
    data = {}
    results.each_with_index do |result, index|
      next unless result.success?
      next if result.value.nil? # Don't include nil values in data

      # Get the original field name from the fields array
      original_field = @fields[index]
      # Use original_name if it exists (for meta: prefixed fields), otherwise use name
      field_name = original_field[:original_name] || original_field[:name]
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
        { name: field }
      when Hash
        result = {
          name: field[:name] || field["name"],
          attribute: field[:attribute] || field["attribute"] || "content"
        }
        # Preserve original_name if it exists
        result[:original_name] = field[:original_name] if field[:original_name]
        result
      else
        raise ScraperErrors::ValidationError, "Invalid meta field format: #{field.class}"
      end
    end
  end

  def validate_inputs
    raise ScraperErrors::ValidationError, "Document is nil" if @document.nil?

    @fields.each do |field|
      validate_meta_name(field[:name])
    end
  end

  def validate_meta_name(name)
    raise ScraperErrors::ValidationError, "Meta tag name cannot be nil" if name.nil?
    raise ScraperErrors::ValidationError, "Meta tag name cannot be empty" if name.to_s.strip.empty?
  end

  def extract_meta_tag(field)
    meta_name = field[:name]
    attribute_to_extract = field[:attribute] || "content"

    # Try each meta attribute type (name, property, http-equiv)
    element = find_meta_element(meta_name)

    value = (element[attribute_to_extract] if element)

    ExtractedField.new(
      selector: meta_name,
      value: value,
      error: nil
    )
  end

  def find_meta_element(meta_name)
    # Try to find meta tag with case-insensitive matching across different attribute types
    META_ATTRIBUTES.each do |attr|
      # Try direct CSS selector first
      element = @document.at_css("meta[#{attr}='#{meta_name}']") ||
                @document.at_css("meta[#{attr}=\"#{meta_name}\"]")

      return element if element

      # Try case-insensitive match using XPath
      xpath = "//meta[translate(@#{attr}, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', " \
              "'abcdefghijklmnopqrstuvwxyz')='#{meta_name.downcase}']"
      element = @document.at_xpath(xpath)
      return element if element
    end

    nil
  end
end
