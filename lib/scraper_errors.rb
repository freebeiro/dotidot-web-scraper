# frozen_string_literal: true

# Custom exception hierarchy for the Dotidot Web Scraper
# Provides structured error handling with specialized error types
module ScraperErrors
  # Base error class for all scraper-related exceptions
  class BaseError < StandardError; end

  # Raised when input validation fails (invalid URLs, malformed data, etc.)
  class ValidationError < BaseError; end

  # Raised when security violations are detected (SSRF attempts, blocked hosts, etc.)
  class SecurityError < BaseError; end

  # Raised when network operations fail (timeouts, connection errors, HTTP errors, etc.)
  class NetworkError < BaseError; end
end
