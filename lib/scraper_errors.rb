# frozen_string_literal: true

# Custom exception hierarchy for the Dotidot Web Scraper
# Provides structured error handling with specialized error types
module ScraperErrors
  # Base error class for all scraper-related exceptions
  class BaseError < StandardError
    attr_reader :error_code, :context, :suggested_action

    def initialize(message = nil, error_code: nil, context: {}, suggested_action: nil)
      super(message)
      @error_code = error_code || self.class.name.demodulize.underscore.upcase
      @context = context
      @suggested_action = suggested_action
    end
  end

  # Raised when input validation fails (invalid URLs, malformed data, etc.)
  class ValidationError < BaseError
    def initialize(message = nil, **options)
      options[:error_code] ||= "VALIDATION_ERROR"
      options[:suggested_action] ||= "Please check your input and try again"
      super
    end
  end

  # Raised when security violations are detected (SSRF attempts, blocked hosts, etc.)
  class SecurityError < BaseError
    def initialize(message = nil, **options)
      options[:error_code] ||= "SECURITY_ERROR"
      options[:suggested_action] ||= "The requested URL is not allowed for security reasons"
      super
    end
  end

  # Raised when network operations fail (timeouts, connection errors, HTTP errors, etc.)
  class NetworkError < BaseError
    attr_reader :retry_after, :status_code

    def initialize(message = nil, retry_after: nil, status_code: nil, **options)
      options[:error_code] ||= "NETWORK_ERROR"
      options[:suggested_action] ||= "Please try again later"
      super(message, **options)
      @retry_after = retry_after
      @status_code = status_code
    end
  end

  # Raised when HTML parsing fails (malformed HTML, encoding issues, etc.)
  class ParsingError < BaseError
    def initialize(message = nil, **options)
      options[:error_code] ||= "PARSING_ERROR"
      options[:suggested_action] ||= "The webpage content could not be parsed"
      super
    end
  end

  # Raised when rate limits are exceeded
  class RateLimitError < BaseError
    attr_reader :retry_after

    def initialize(message = nil, retry_after: 60, **options)
      options[:error_code] ||= "RATE_LIMIT_ERROR"
      options[:suggested_action] ||= "Too many requests. Please wait before trying again"
      super(message, **options)
      @retry_after = retry_after
    end
  end

  # Raised when request times out
  class TimeoutError < NetworkError
    def initialize(message = nil, timeout: nil, **options)
      options[:error_code] ||= "TIMEOUT_ERROR"
      options[:context] ||= {}
      options[:context][:timeout] = timeout if timeout
      options[:suggested_action] ||= "The request took too long. Please try again"
      super(message, **options)
    end
  end

  # Raised when data extraction fails (CSS selector errors, missing elements, etc.)
  class ExtractionError < BaseError
    def initialize(message = nil, **options)
      options[:error_code] ||= "EXTRACTION_ERROR"
      options[:suggested_action] ||= "Data could not be extracted from the webpage"
      super
    end
  end
end
