# frozen_string_literal: true

require "http"
require_relative "../../lib/scraper_errors"

# HTTP client service with retry logic and configurable timeouts
# Handles network requests with exponential backoff retry strategy
class HttpClientService
  # Default configuration values
  DEFAULT_TIMEOUT = 30
  DEFAULT_MAX_RETRIES = 3
  DEFAULT_RETRY_DELAY = 1.0
  MAX_RETRY_DELAY = 30.0
  DEFAULT_USER_AGENT = "Dotidot-Scraper/1.0"

  # HTTP errors that should trigger a retry
  RETRYABLE_ERRORS = [
    HTTP::ConnectionError,
    HTTP::TimeoutError,
    HTTP::RequestError,
    Errno::ECONNREFUSED,
    Errno::EHOSTUNREACH,
    Errno::ENETUNREACH,
    SocketError
  ].freeze

  def self.call(url, options = {})
    new(url, options).call
  end

  def initialize(url, options = {})
    @url = url
    @timeout = options[:timeout] || DEFAULT_TIMEOUT
    @max_retries = options[:max_retries] || DEFAULT_MAX_RETRIES
    @user_agent = options[:user_agent] || DEFAULT_USER_AGENT
  end

  def call
    attempt = 0
    delay = DEFAULT_RETRY_DELAY
    start_time = Time.current

    begin
      attempt += 1
      response = perform_request

      {
        success: true,
        body: response[:body],
        status: response[:status],
        headers: response[:headers],
        response_time: Time.current - start_time,
        attempts: attempt
      }
    rescue *RETRYABLE_ERRORS => e
      if attempt < @max_retries
        Rails.logger.warn("HTTP request failed (attempt #{attempt}/#{@max_retries}): #{e.message}")
        sleep(delay)
        delay = [delay * 2, MAX_RETRY_DELAY].min
        retry
      else
        {
          success: false,
          error: "Failed to fetch URL after #{@max_retries} attempts: #{e.message}",
          attempts: attempt,
          response_time: Time.current - start_time
        }
      end
    rescue => e
      {
        success: false,
        error: e.message,
        attempts: attempt,
        response_time: Time.current - start_time
      }
    end
  end

  private

  def perform_request
    response = HTTP
               .headers("User-Agent" => @user_agent)
               .timeout(@timeout)
               .follow
               .get(@url)

    unless response.status.success?
      raise ScraperErrors::NetworkError, "HTTP request failed with status #{response.code}: #{response.reason}"
    end

    {
      body: response.body.to_s,
      status: response.code,
      headers: response.headers.to_h.transform_keys(&:downcase)
    }
  end
end
