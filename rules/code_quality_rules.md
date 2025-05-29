# Code Quality Rules - Dotidot Web Scraper Challenge

## 🏗️ Rails Architecture Checklist

### MVC Pattern Adherence
- [ ] **Skinny controllers** - logic in services/models, not controllers
- [ ] **Fat models vs service objects** - extract complex logic to services
- [ ] **Single responsibility** - each class has one clear purpose
- [ ] **Separation of concerns** - business logic separate from presentation
- [ ] **DRY principle** - don't repeat yourself

### Controller Best Practices
- [ ] **Keep actions simple** (max 10 lines)
- [ ] **One action per method** - no hidden side effects
- [ ] **Use strong parameters** for input validation
- [ ] **Delegate to service objects** for business logic
- [ ] **Consistent error handling** across all actions

### Controller Example
```ruby
# ✅ GOOD - Skinny controller
class DataController < ApplicationController
  def index
    result = WebScraperService.call(scraper_params[:url], scraper_params[:fields])
    render json: result[:data], status: :ok
  rescue ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue RateLimitError => e
    render json: { error: e.message }, status: :too_many_requests
  end
  
  private
  
  def scraper_params
    params.permit(:url, fields: {})
  end
end

# ❌ BAD - Fat controller with business logic
class DataController < ApplicationController
  def index
    # Validate URL
    uri = URI.parse(params[:url])
    raise 'Invalid URL' unless %w[http https].include?(uri.scheme)
    
    # Check rate limit
    if rate_limit_exceeded?(request.ip)
      render json: { error: 'Rate limit exceeded' }, status: 429
      return
    end
    
    # Fetch and parse HTML
    response = HTTP.get(params[:url])
    doc = Nokogiri::HTML(response.body)
    
    # Extract data
    result = {}
    params[:fields].each do |key, selector|
      result[key] = doc.at_css(selector)&.text&.strip
    end
    
    render json: result
  end
end
```

## 🛠️ Service Object Design Checklist

### Service Object Principles
- [ ] **Single responsibility** - one clear business operation
- [ ] **Descriptive class names** - explain what the service does
- [ ] **Simple interface** - usually a single `.call` method
- [ ] **Return consistent data structure** - hash with data/status
- [ ] **Proper error handling** - raise specific exceptions

### Service Object Structure
- [ ] **Use .call class method** for stateless operations
- [ ] **Initialize with dependencies** if needed
- [ ] **Validate inputs** at the beginning
- [ ] **Return structured results** (success/error data)
- [ ] **Keep methods private** except for public interface

### Service Object Examples
```ruby
# ✅ GOOD - Well-designed service object
class WebScraperService
  def self.call(url, fields)
    new(url, fields).call
  end
  
  def initialize(url, fields)
    @url = url
    @fields = fields
  end
  
  def call
    validate_inputs!
    
    cached_result = check_cache
    return format_cached_response(cached_result) if cached_result
    
    html_content = fetch_html
    extracted_data = extract_data(html_content)
    
    cache_result(extracted_data)
    format_response(extracted_data)
  end
  
  private
  
  attr_reader :url, :fields
  
  def validate_inputs!
    UrlValidatorService.call(url)
    FieldsValidatorService.call(fields)
  end
  
  def check_cache
    PageCacheService.get(cache_key)
  end
  
  def fetch_html
    HttpClientService.call(url)
  end
  
  def extract_data(html)
    DataExtractionService.call(html, fields)
  end
  
  def cache_result(data)
    PageCacheService.set(cache_key, data)
  end
  
  def cache_key
    @cache_key ||= "scraper:#{Digest::SHA256.hexdigest("#{url}:#{fields.to_json}")}"
  end
  
  def format_response(data)
    {
      data: data,
      cached: false,
      timestamp: Time.current
    }
  end
  
  def format_cached_response(data)
    {
      data: data,
      cached: true,
      timestamp: Time.current
    }
  end
end
```

## 📝 Naming Conventions Checklist

### Class and Method Naming
- [ ] **Use descriptive names** that explain purpose
- [ ] **Follow Rails naming conventions** (PascalCase for classes)
- [ ] **Use verb phrases for methods** (extract_data, validate_url)
- [ ] **Boolean methods end with ?** (valid?, cached?)
- [ ] **Dangerous methods end with !** (save!, validate!)

### Variable and Constant Naming
- [ ] **Use snake_case** for variables and methods
- [ ] **Use UPPER_CASE** for constants
- [ ] **Avoid abbreviations** unless widely understood
- [ ] **Use meaningful names** (user_count not cnt)
- [ ] **Keep scope appropriate** (short names in short methods)

### Naming Examples
```ruby
# ✅ GOOD - Clear, descriptive names
class UrlValidatorService
  ALLOWED_SCHEMES = %w[http https].freeze
  MAX_URL_LENGTH = 2048
  
  def self.call(url)
    new(url).validate!
  end
  
  def initialize(url)
    @url = url
  end
  
  def validate!
    check_url_format!
    check_url_length!
    check_url_scheme!
    check_for_blocked_hosts!
    
    url
  end
  
  private
  
  attr_reader :url
  
  def valid_url_format?
    URI.parse(url)
    true
  rescue URI::InvalidURIError
    false
  end
  
  def blocked_host?
    # Implementation here
  end
end

# ❌ BAD - Unclear, abbreviated names
class UrlValidator
  SCHEMES = %w[http https]
  MAX_LEN = 2048
  
  def self.call(u)
    new(u).validate
  end
  
  def initialize(u)
    @u = u
  end
  
  def validate
    chk_fmt
    chk_len
    chk_scheme
    chk_hosts
    @u
  end
end
```

## 🎯 SOLID Principles Checklist

### Single Responsibility Principle (SRP)
- [ ] **Each class has one reason to change**
- [ ] **Methods do one thing well**
- [ ] **Separate concerns** (validation, business logic, persistence)
- [ ] **Avoid god objects** (classes that do everything)
- [ ] **Clear class purpose** from name and methods

### Open/Closed Principle (OCP)
- [ ] **Open for extension** - can add new behavior
- [ ] **Closed for modification** - don't change existing code
- [ ] **Use inheritance/composition** for extensions
- [ ] **Plugin architecture** where appropriate
- [ ] **Strategy pattern** for varying algorithms

### Dependency Inversion Principle (DIP)
- [ ] **Depend on abstractions** not concretions
- [ ] **Inject dependencies** rather than hard-coding
- [ ] **Use interfaces/contracts** where possible
- [ ] **Mock-friendly design** for testing
- [ ] **Avoid tight coupling** between classes

### SOLID Implementation Example
```ruby
# ✅ GOOD - Follows SOLID principles
# Single Responsibility - each class has one job
class WebScraperService
  def initialize(url_validator: UrlValidatorService,
                 http_client: HttpClientService,
                 data_extractor: DataExtractionService,
                 cache_service: PageCacheService)
    @url_validator = url_validator
    @http_client = http_client
    @data_extractor = data_extractor
    @cache_service = cache_service
  end
  
  def call(url, fields)
    @url_validator.call(url)
    
    cached_data = @cache_service.get(cache_key(url, fields))
    return format_cached_response(cached_data) if cached_data
    
    html = @http_client.call(url)
    data = @data_extractor.call(html, fields)
    
    @cache_service.set(cache_key(url, fields), data)
    format_response(data)
  end
  
  private
  
  # ... helper methods
end

# ❌ BAD - Violates multiple SOLID principles
class WebScraperService
  def call(url, fields)
    # SRP violation - doing validation, HTTP, extraction, caching
    raise 'Invalid URL' unless url =~ /\Ahttps?:\/\//
    
    response = HTTP.get(url)
    doc = Nokogiri::HTML(response.body)
    
    # Hard-coded dependencies (DIP violation)
    cache_key = "scraper:#{Digest::SHA256.hexdigest(url)}"
    cached = Rails.cache.read(cache_key)
    return cached if cached
    
    result = {}
    fields.each { |k, v| result[k] = doc.at_css(v)&.text }
    
    Rails.cache.write(cache_key, result)
    result
  end
end
```

## 🔧 Error Handling Checklist

### Exception Design
- [ ] **Create custom exception classes** for different error types
- [ ] **Inherit from appropriate base classes** (StandardError)
- [ ] **Use meaningful exception names** (ValidationError, RateLimitError)
- [ ] **Include helpful error messages**
- [ ] **Add context to exceptions** when re-raising

### Error Handling Patterns
- [ ] **Fail fast** - validate inputs early
- [ ] **Handle errors at appropriate level**
- [ ] **Don't catch and ignore** unless intentional
- [ ] **Log errors with context**
- [ ] **Provide user-friendly messages**

### Custom Exception Example
```ruby
# ✅ GOOD - Custom exception hierarchy
module ScraperErrors
  class BaseError < StandardError
    attr_reader :context
    
    def initialize(message, context = {})
      super(message)
      @context = context
    end
  end
  
  class ValidationError < BaseError; end
  class SecurityError < BaseError; end
  class RateLimitError < BaseError; end
  class NetworkError < BaseError; end
  class ParsingError < BaseError; end
end

# Usage in services
class UrlValidatorService
  def self.call(url)
    raise ScraperErrors::ValidationError.new(
      "Invalid URL format: #{url}",
      { url: url, validator: 'UrlValidatorService' }
    ) unless valid_url_format?(url)
    
    raise ScraperErrors::SecurityError.new(
      "Blocked host detected: #{extract_host(url)}",
      { url: url, host: extract_host(url) }
    ) if blocked_host?(url)
    
    url
  end
end
```

## 📚 Documentation Checklist

### Code Documentation
- [ ] **Document public API methods** with YARD/RDoc
- [ ] **Explain complex algorithms** with comments
- [ ] **Document assumptions** and constraints
- [ ] **Include usage examples** for services
- [ ] **Keep documentation up-to-date**

### README Documentation
- [ ] **Clear project description** and purpose
- [ ] **Installation instructions** step-by-step
- [ ] **API usage examples** with curl/request examples
- [ ] **Configuration options** explained
- [ ] **Contributing guidelines**

### Documentation Examples
```ruby
# ✅ GOOD - Well-documented service
# Service responsible for validating URLs before scraping
# Ensures URLs are safe and follow security guidelines
#
# @example Basic usage
#   UrlValidatorService.call('https://example.com')
#   #=> 'https://example.com'
#
# @example Invalid URL
#   UrlValidatorService.call('invalid-url')
#   #=> raises ScraperErrors::ValidationError
#
class UrlValidatorService
  # Maximum allowed URL length to prevent DoS attacks
  MAX_URL_LENGTH = 2048
  
  # Validates a URL for safety and format compliance
  #
  # @param url [String] The URL to validate
  # @return [String] The validated URL
  # @raise [ScraperErrors::ValidationError] When URL format is invalid
  # @raise [ScraperErrors::SecurityError] When URL poses security risk
  def self.call(url)
    # Implementation here
  end
end
```

## 🧹 Code Organization Checklist

### File Structure
- [ ] **Follow Rails conventions** for file placement
- [ ] **Group related classes** in modules/namespaces
- [ ] **Use descriptive file names** matching class names
- [ ] **Organize by feature** not by layer when possible
- [ ] **Keep related code together**

### Module Organization
- [ ] **Use modules for namespacing** related classes
- [ ] **Extract common functionality** to mixins
- [ ] **Avoid deep nesting** (max 2-3 levels)
- [ ] **Clear module responsibilities**
- [ ] **Proper require statements**

### Organization Example
```ruby
# File structure for web scraper
app/
├── controllers/
│   └── data_controller.rb
├── services/
│   ├── web_scraper_service.rb
│   ├── validators/
│   │   ├── url_validator_service.rb
│   │   └── fields_validator_service.rb
│   ├── extractors/
│   │   ├── data_extraction_service.rb
│   │   ├── css_extraction_strategy.rb
│   │   └── meta_extraction_strategy.rb
│   └── http/
│       └── http_client_service.rb
├── lib/
│   └── scraper_errors.rb
└── models/
    └── scrape_result.rb

# Module organization
module WebScraper
  module Validators
    class UrlValidatorService
      # Implementation
    end
  end
  
  module Extractors
    class DataExtractionService
      # Implementation
    end
  end
end
```

## ⚡ Performance Code Quality Checklist

### Efficient Coding Practices
- [ ] **Avoid N+1 queries** in database operations
- [ ] **Use appropriate data structures** (Hash vs Array)
- [ ] **Minimize object allocation** in hot paths
- [ ] **Use lazy evaluation** where beneficial
- [ ] **Cache expensive computations**

### Memory Management
- [ ] **Avoid large string concatenation** (use Array#join)
- [ ] **Use symbols for fixed strings** (hash keys)
- [ ] **Stream large data processing**
- [ ] **Release references** to large objects
- [ ] **Monitor memory usage** in development

### Performance Code Examples
```ruby
# ✅ GOOD - Efficient data processing
class DataExtractionService
  def self.call(html, fields)
    doc = Nokogiri::HTML(html)
    
    # Efficient field extraction
    fields.each_with_object({}) do |(key, selector), result|
      result[key.to_sym] = extract_field(doc, selector)
    end
  end
  
  private_class_method def self.extract_field(doc, selector)
    element = doc.at_css(selector)
    element&.text&.strip
  end
end

# ❌ BAD - Inefficient processing
class DataExtractionService
  def self.call(html, fields)
    result = {}
    
    fields.each do |key, selector|
      # Parsing HTML for each field - inefficient!
      doc = Nokogiri::HTML(html)
      element = doc.at_css(selector)
      result[key] = element ? element.text.strip : nil
    end
    
    result
  end
end
```

---

## ✅ Code Quality Implementation Checklist

### Before Writing Code
- [ ] Understand the requirements completely
- [ ] Design the class/method responsibilities
- [ ] Plan for error handling and edge cases
- [ ] Consider performance implications
- [ ] Think about testing strategy

### During Code Writing
- [ ] Follow naming conventions consistently
- [ ] Keep methods short and focused
- [ ] Write self-documenting code
- [ ] Handle errors appropriately
- [ ] Consider SOLID principles

### After Code Implementation
- [ ] Review for code smells and refactor
- [ ] Add appropriate documentation
- [ ] Ensure test coverage is adequate
- [ ] Verify performance is acceptable
- [ ] Check for security vulnerabilities

### Code Review Checklist
- [ ] Code follows project conventions
- [ ] Logic is clear and maintainable
- [ ] Error handling is comprehensive
- [ ] Performance is acceptable
- [ ] Security considerations addressed
- [ ] Tests cover the functionality
- [ ] Documentation is up-to-date

## 🚨 Automated Quality Enforcement

### Pre-commit Checks (MANDATORY)
- [ ] **Run `bundle exec rspec`** - ALL tests must pass (0 failures)
- [ ] **Run `bundle exec rubocop`** - ALL offenses must be fixed (0 violations)
- [ ] **Check git status** - Only relevant files should be staged
- [ ] **Review diff** - Ensure changes match intended scope

### Pre-push Checks (CRITICAL)
- [ ] **Full test suite** must pass without any pending tests for core features
- [ ] **Rubocop compliance** with zero violations
- [ ] **No debug code** (binding.pry, puts, console.log)
- [ ] **No commented code** unless explicitly documented

### Development Workflow Enforcement
```bash
# MANDATORY pre-commit workflow
git add <files>
bundle exec rspec          # MUST pass 100%
bundle exec rubocop        # MUST show 0 offenses
git commit -m "message"

# MANDATORY pre-push workflow  
bundle exec rspec          # Final verification
git push origin branch
```

### Automated Checks Setup
```bash
# Add to .git/hooks/pre-commit
#!/bin/sh
echo "Running pre-commit checks..."

echo "1. Running RSpec tests..."
bundle exec rspec
if [ $? -ne 0 ]; then
  echo "❌ Tests failed. Fix failing tests before committing."
  exit 1
fi

echo "2. Running Rubocop..."
bundle exec rubocop
if [ $? -ne 0 ]; then
  echo "❌ Rubocop violations found. Fix code style before committing."
  exit 1
fi

echo "✅ All pre-commit checks passed!"
exit 0
```

### Emergency Recovery Protocol
If you find yourself with 100+ failing tests again:

1. **STOP** - Don't panic commit or push
2. **Backup current state** - `cp -r spec spec_backup_$(date +%Y%m%d_%H%M%S)`
3. **Run tests incrementally** - Fix by service/controller, not all at once
4. **Use test filtering** - `bundle exec rspec spec/services/specific_service_spec.rb`
5. **Fix rubocop incrementally** - `bundle exec rubocop --autocorrect`
6. **Remove backup** when all tests pass - `rm -rf spec_backup_*`

**Remember: Code quality is not just about making it work - it's about making it maintainable, testable, and understandable for the team!**

**⚠️ NEVER COMMIT WITH FAILING TESTS OR RUBOCOP VIOLATIONS - This is non-negotiable!**