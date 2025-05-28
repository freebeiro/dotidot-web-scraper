# Web Scraping Rules - Dotidot Web Scraper Challenge

## 🌐 Nokogiri HTML Parsing Checklist

### Nokogiri Setup
- [ ] **Add nokogiri gem** to Gemfile
- [ ] **Parse HTML correctly** using Nokogiri::HTML()
- [ ] **Handle encoding issues** (UTF-8, ISO-8859-1)
- [ ] **Validate HTML structure** before parsing
- [ ] **Handle malformed HTML** gracefully

### HTML Parsing Best Practices
- [ ] **Parse once, query multiple times** - avoid re-parsing same document
- [ ] **Use efficient selectors** - prefer ID > class > tag
- [ ] **Cache parsed documents** when possible
- [ ] **Handle empty/null results** from selectors
- [ ] **Clean up resources** after parsing

### Nokogiri Implementation Example
```ruby
class HtmlParserService
  def self.call(html_content)
    # Parse HTML once
    document = Nokogiri::HTML(html_content)
    
    # Validate document structure
    raise ParsingError, "Invalid HTML structure" if document.nil?
    
    document
  rescue => e
    raise ParsingError, "HTML parsing failed: #{e.message}"
  end
end

# Usage in extraction service
class DataExtractionService
  def self.call(html, fields)
    document = HtmlParserService.call(html)
    
    fields.each_with_object({}) do |(key, selector), result|
      result[key] = extract_field_safely(document, selector)
    end
  end
  
  private_class_method def self.extract_field_safely(document, selector)
    element = document.at_css(selector)
    element&.text&.strip
  rescue => e
    Rails.logger.warn("Failed to extract field with selector '#{selector}': #{e.message}")
    nil
  end
end
```

## 🎯 CSS Selector Strategy Checklist

### Robust Selector Design
- [ ] **Use specific selectors** - avoid overly generic ones
- [ ] **Prefer IDs over classes** when available
- [ ] **Avoid positional selectors** (:nth-child, :first, :last)
- [ ] **Test selectors across multiple pages** for consistency
- [ ] **Handle selector failures** gracefully

### CSS Selector Best Practices
- [ ] **Use semantic selectors** based on content meaning
- [ ] **Combine selectors** for specificity (div.product h2.title)
- [ ] **Avoid deeply nested selectors** (max 3-4 levels)
- [ ] **Use attribute selectors** when appropriate [data-id="123"]
- [ ] **Test with browser dev tools** before implementation

### Selector Examples
```ruby
# ✅ GOOD - Robust, semantic selectors
SELECTORS = {
  # Specific, meaningful selectors
  product_title: 'h1.product-title, h1[data-testid="product-title"]',
  product_price: '.price-current, .current-price, [data-price]',
  product_description: '.product-description, .description, [role="description"]',
  
  # Fallback selectors for flexibility
  generic_title: 'h1, .title, [data-title]',
  generic_price: '[class*="price"], [data-price], .cost'
}.freeze

# ❌ BAD - Fragile, position-dependent selectors
BAD_SELECTORS = {
  title: 'div:nth-child(2) > p:first-child',  # Too specific
  price: 'span',                              # Too generic
  description: 'body > div > div > p'         # Brittle structure dependency
}

# Implementation with fallback strategy
class CssSelectorService
  def self.extract_with_fallbacks(document, selector_key)
    selectors = SELECTORS[selector_key].split(', ')
    
    selectors.each do |selector|
      element = document.at_css(selector.strip)
      return element.text.strip if element
    end
    
    nil # All selectors failed
  end
end
```

## 📋 Meta Tag Extraction Checklist

### Meta Tag Handling
- [ ] **Support common meta tags** (description, keywords, og:*)
- [ ] **Handle multiple meta formats** (name, property, http-equiv)
- [ ] **Extract specific meta values** based on user request
- [ ] **Handle missing meta tags** gracefully
- [ ] **Validate meta tag names** for security

### Meta Tag Implementation
- [ ] **Use CSS attribute selectors** for meta extraction
- [ ] **Support OpenGraph tags** (og:title, og:description, og:image)
- [ ] **Support Twitter Card tags** (twitter:title, twitter:image)
- [ ] **Handle case-insensitive matching**
- [ ] **Return structured meta data**

### Meta Extraction Examples
```ruby
class MetaExtractionService
  # Common meta tag patterns
  META_SELECTORS = {
    'description' => 'meta[name="description"], meta[property="description"]',
    'keywords' => 'meta[name="keywords"]',
    'og:title' => 'meta[property="og:title"]',
    'og:description' => 'meta[property="og:description"]',
    'og:image' => 'meta[property="og:image"]',
    'twitter:title' => 'meta[name="twitter:title"], meta[property="twitter:title"]',
    'twitter:image' => 'meta[name="twitter:image"], meta[property="twitter:image"]'
  }.freeze
  
  def self.call(document, meta_fields)
    meta_fields.each_with_object({}) do |meta_name, result|
      result[meta_name] = extract_meta_content(document, meta_name)
    end
  end
  
  private_class_method def self.extract_meta_content(document, meta_name)
    # Try predefined selector first
    selector = META_SELECTORS[meta_name]
    
    if selector
      element = document.at_css(selector)
      return element['content'] if element
    end
    
    # Fallback to generic meta tag search
    generic_selector = "meta[name=\"#{meta_name}\"], meta[property=\"#{meta_name}\"]"
    element = document.at_css(generic_selector)
    element&.[]('content')
  end
end

# Usage example
meta_data = MetaExtractionService.call(document, ['description', 'og:image', 'keywords'])
# Returns: { 'description' => '...', 'og:image' => 'https://...', 'keywords' => '...' }
```

## 🔄 Data Extraction Patterns Checklist

### Extraction Strategy
- [ ] **Use strategy pattern** for different extraction types
- [ ] **Handle mixed field types** (CSS selectors + meta tags)
- [ ] **Normalize extracted data** (trim whitespace, handle encoding)
- [ ] **Validate extracted content** for reasonable formats
- [ ] **Log extraction failures** for debugging

### Data Processing
- [ ] **Clean extracted text** (remove extra whitespace, special chars)
- [ ] **Handle different content types** (text, numbers, URLs)
- [ ] **Preserve original data structure** when possible
- [ ] **Apply consistent formatting** across fields
- [ ] **Handle multi-language content** appropriately

### Extraction Strategy Implementation
```ruby
module ExtractionStrategies
  class BaseStrategy
    def self.extract(document, selector)
      raise NotImplementedError, "Subclasses must implement extract method"
    end
    
    protected
    
    def self.clean_text(text)
      return nil if text.nil?
      
      text.strip
          .gsub(/\s+/, ' ')           # Normalize whitespace
          .gsub(/\u00A0/, ' ')        # Replace &nbsp; with space
          .strip
    end
  end
  
  class CssStrategy < BaseStrategy
    def self.extract(document, selector)
      element = document.at_css(selector)
      return nil unless element
      
      clean_text(element.text)
    end
  end
  
  class MetaStrategy < BaseStrategy
    def self.extract(document, meta_names)
      MetaExtractionService.call(document, meta_names)
    end
  end
  
  class AttributeStrategy < BaseStrategy
    def self.extract(document, selector, attribute)
      element = document.at_css(selector)
      return nil unless element
      
      element[attribute]
    end
  end
end

# Factory for choosing extraction strategy
class ExtractionStrategyFactory
  def self.get_strategy(field_type)
    case field_type
    when :css then ExtractionStrategies::CssStrategy
    when :meta then ExtractionStrategies::MetaStrategy
    when :attribute then ExtractionStrategies::AttributeStrategy
    else
      raise ArgumentError, "Unknown field type: #{field_type}"
    end
  end
end
```

## 🚦 Error Handling & Resilience Checklist

### Robust Error Handling
- [ ] **Handle malformed HTML** gracefully
- [ ] **Manage selector failures** without crashing
- [ ] **Log parsing errors** with context
- [ ] **Provide fallback mechanisms** for critical data
- [ ] **Return partial results** when some fields fail

### Content Validation
- [ ] **Validate selector syntax** before use
- [ ] **Check for reasonable content length** (not empty, not too long)
- [ ] **Detect placeholder/dummy content**
- [ ] **Handle special characters** and encoding issues
- [ ] **Validate URL formats** for extracted links

### Error Handling Implementation
```ruby
class ResilientDataExtractor
  MAX_FIELD_LENGTH = 10_000
  MIN_FIELD_LENGTH = 1
  
  def self.call(document, fields)
    extraction_results = {}
    extraction_errors = {}
    
    fields.each do |field_name, field_config|
      begin
        result = extract_field_with_validation(document, field_config)
        extraction_results[field_name] = result if result
      rescue => e
        extraction_errors[field_name] = e.message
        Rails.logger.warn("Field extraction failed for '#{field_name}': #{e.message}")
      end
    end
    
    {
      data: extraction_results,
      errors: extraction_errors,
      success: extraction_errors.empty?
    }
  end
  
  private_class_method def self.extract_field_with_validation(document, field_config)
    # Handle different field types
    if field_config.is_a?(String)
      result = ExtractionStrategies::CssStrategy.extract(document, field_config)
    elsif field_config.is_a?(Array)
      result = ExtractionStrategies::MetaStrategy.extract(document, field_config)
    else
      raise ArgumentError, "Invalid field configuration: #{field_config}"
    end
    
    # Validate result
    validate_extracted_content(result) if result
    
    result
  end
  
  private_class_method def self.validate_extracted_content(content)
    case content
    when String
      validate_text_content(content)
    when Hash
      content.each_value { |value| validate_text_content(value) if value.is_a?(String) }
    end
  end
  
  private_class_method def self.validate_text_content(text)
    return if text.nil?
    
    if text.length > MAX_FIELD_LENGTH
      raise ContentError, "Content too long: #{text.length} chars"
    end
    
    if text.length < MIN_FIELD_LENGTH
      raise ContentError, "Content too short or empty"
    end
    
    # Check for common placeholder patterns
    if text.match?(/lorem ipsum|placeholder|dummy|test content/i)
      raise ContentError, "Placeholder content detected"
    end
  end
end
```

## 🤝 Ethical Scraping Checklist

### Respect Website Policies
- [ ] **Check robots.txt** for scraping guidelines
- [ ] **Review terms of service** for scraping restrictions
- [ ] **Respect rate limiting** and server capacity
- [ ] **Use appropriate User-Agent** identification
- [ ] **Don't overload servers** with requests

### Responsible Scraping Practices
- [ ] **Implement delays** between requests (1-2 seconds minimum)
- [ ] **Monitor target site performance** and back off if needed
- [ ] **Cache results** to avoid repeated requests
- [ ] **Handle errors gracefully** without hammering servers
- [ ] **Respect copyright** and intellectual property

### Ethical Implementation
```ruby
class EthicalScrapingService
  DELAY_BETWEEN_REQUESTS = 2.seconds
  MAX_RETRIES = 3
  BACKOFF_MULTIPLIER = 2
  
  def self.call(url, fields)
    # Check if we should scrape this URL
    validate_scraping_permissions(url)
    
    # Implement polite delays
    enforce_rate_limiting(url)
    
    # Scrape with retries and backoff
    scrape_with_backoff(url, fields)
  end
  
  private_class_method def self.validate_scraping_permissions(url)
    # Check robots.txt (simplified - could use robotstxt gem)
    robots_url = URI.join(url, '/robots.txt')
    
    # Log scraping activity for audit
    Rails.logger.info("Scraping request for #{URI.parse(url).host}")
  end
  
  private_class_method def self.enforce_rate_limiting(url)
    domain = URI.parse(url).host
    last_request_key = "scraper:last_request:#{domain}"
    
    last_request_time = Rails.cache.read(last_request_key)
    
    if last_request_time
      time_since_last = Time.current - last_request_time
      if time_since_last < DELAY_BETWEEN_REQUESTS
        sleep_time = DELAY_BETWEEN_REQUESTS - time_since_last
        sleep(sleep_time)
      end
    end
    
    Rails.cache.write(last_request_key, Time.current, expires_in: 1.hour)
  end
  
  private_class_method def self.scrape_with_backoff(url, fields)
    retries = 0
    
    begin
      html = HttpClientService.call(url)
      DataExtractionService.call(html, fields)
      
    rescue HTTP::Error, Timeout::Error => e
      retries += 1
      
      if retries <= MAX_RETRIES
        delay = DELAY_BETWEEN_REQUESTS * (BACKOFF_MULTIPLIER ** retries)
        Rails.logger.warn("Scraping failed (attempt #{retries}), retrying in #{delay}s: #{e.message}")
        sleep(delay)
        retry
      else
        raise ScrapingError, "Scraping failed after #{MAX_RETRIES} attempts: #{e.message}"
      end
    end
  end
end
```

## 📊 Data Quality & Validation Checklist

### Content Quality Checks
- [ ] **Validate extracted data format** (URLs, emails, numbers)
- [ ] **Check for minimum content length** requirements
- [ ] **Detect and filter spam content**
- [ ] **Validate data consistency** across fields
- [ ] **Check for duplicate or placeholder content**

### Data Sanitization
- [ ] **Remove HTML entities** (decode &amp;, &lt;, etc.)
- [ ] **Normalize whitespace** and line breaks
- [ ] **Strip unwanted characters** but preserve meaning
- [ ] **Handle encoding issues** properly
- [ ] **Validate URLs and links** if extracted

### Quality Validation Implementation
```ruby
class DataQualityValidator
  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  URL_REGEX = /\Ahttps?:\/\/[^\s]+\z/
  PHONE_REGEX = /\A[\d\s\-\(\)\+\.]+\z/
  
  def self.validate_and_clean(data)
    return {} if data.nil? || data.empty?
    
    data.each_with_object({}) do |(key, value), clean_data|
      cleaned_value = clean_field_value(value)
      clean_data[key] = cleaned_value if valid_content?(cleaned_value)
    end
  end
  
  private_class_method def self.clean_field_value(value)
    return value unless value.is_a?(String)
    
    # Decode HTML entities
    decoded = CGI.unescapeHTML(value)
    
    # Normalize whitespace
    normalized = decoded.gsub(/\s+/, ' ').strip
    
    # Remove zero-width characters and other invisible chars
    cleaned = normalized.gsub(/[\u200B-\u200D\uFEFF]/, '')
    
    cleaned.empty? ? nil : cleaned
  end
  
  private_class_method def self.valid_content?(content)
    return false if content.nil? || content.empty?
    
    # Check for minimum length
    return false if content.length < 3
    
    # Check for common placeholder patterns
    return false if placeholder_content?(content)
    
    # Check for spam patterns
    return false if spam_content?(content)
    
    true
  end
  
  private_class_method def self.placeholder_content?(content)
    placeholders = [
      /lorem ipsum/i,
      /placeholder/i,
      /dummy text/i,
      /sample content/i,
      /test data/i,
      /\A[x\s]+\z/,  # Just x's and spaces
      /\A[\.]+\z/     # Just dots
    ]
    
    placeholders.any? { |pattern| content.match?(pattern) }
  end
  
  private_class_method def self.spam_content?(content)
    # Check for excessive repetition
    return true if content.scan(/(.{3,})\1{2,}/).any?
    
    # Check for excessive punctuation
    return true if content.count('!?.,;:') > content.length * 0.3
    
    false
  end
end
```

---

## ✅ Web Scraping Implementation Checklist

### Before Implementing Scraping
- [ ] Research target website structure and patterns
- [ ] Check robots.txt and terms of service
- [ ] Plan for robust CSS selector strategy
- [ ] Design error handling and fallback mechanisms
- [ ] Consider caching and rate limiting requirements

### During Scraping Implementation
- [ ] Use Nokogiri for efficient HTML parsing
- [ ] Implement robust CSS selector patterns
- [ ] Handle meta tag extraction properly
- [ ] Add comprehensive error handling
- [ ] Follow ethical scraping practices

### After Scraping Implementation
- [ ] Test with various website structures
- [ ] Validate data quality and consistency
- [ ] Monitor scraping performance and errors
- [ ] Document extraction patterns and selectors
- [ ] Ensure compliance with ethical guidelines

### Production Scraping Checklist
- [ ] All selectors tested and robust
- [ ] Error handling covers edge cases
- [ ] Rate limiting properly implemented
- [ ] Data validation catches quality issues
- [ ] Logging provides adequate debugging info
- [ ] Ethical guidelines followed consistently

**Remember: Web scraping should be respectful, reliable, and responsible - extract value while respecting the source!**