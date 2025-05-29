# frozen_string_literal: true

# Provides comprehensive error handling for API controllers with standardized error responses
module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_standard_error
    rescue_from ScraperErrors::ValidationError, with: :handle_validation_error
    rescue_from ScraperErrors::SecurityError, with: :handle_security_error
    rescue_from ScraperErrors::NetworkError, with: :handle_network_error
    rescue_from ScraperErrors::ParsingError, with: :handle_parsing_error
    rescue_from ScraperErrors::TimeoutError, with: :handle_timeout_error
    rescue_from ScraperErrors::RateLimitError, with: :handle_rate_limit_error
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  end

  private

  def handle_validation_error(error)
    log_error(error, level: :warn)
    render_error_response(error, :unprocessable_entity, "VALIDATION_ERROR")
  end

  def handle_security_error(error)
    log_error(error, level: :error)
    render_error_response(error, :forbidden, "SECURITY_ERROR")
  end

  def handle_network_error(error)
    log_error(error, level: :warn)
    render_error_response(error, :bad_gateway, "NETWORK_ERROR")
  end

  def handle_parsing_error(error)
    log_error(error, level: :warn)
    render_error_response(error, :unprocessable_entity, "PARSING_ERROR")
  end

  def handle_timeout_error(error)
    log_error(error, level: :warn)
    render_error_response(error, :bad_gateway, "TIMEOUT_ERROR")
  end

  def handle_rate_limit_error(error)
    log_error(error, level: :warn)
    render_error_response(error, :too_many_requests, "RATE_LIMIT_ERROR")
  end

  def handle_parameter_missing(error)
    log_error(error, level: :info)
    render_error_response(
      ScraperErrors::ValidationError.new("Missing required parameter: #{error.param}"),
      :bad_request,
      "MISSING_PARAMETER"
    )
  end

  def handle_standard_error(error)
    log_error(error, level: :error)

    # In production, hide internal error details
    message = Rails.env.production? ? "An unexpected error occurred" : error.message

    # Create a new error but preserve the original for debugging
    wrapped_error = ScraperErrors::BaseError.new(message)
    backtrace = error.backtrace
    wrapped_error.set_backtrace(backtrace) if backtrace

    render_error_response(
      wrapped_error,
      :internal_server_error,
      "INTERNAL_ERROR"
    )
  end

  def render_error_response(error, status, error_code)
    response_body = build_response_body(error, error_code)
    render json: response_body, status: status
  end

  def build_response_body(error, error_code)
    {
      error: {
        code: error_code,
        message: error.message,
        error_id: SecureRandom.uuid,
        timestamp: Time.current.iso8601,
        request_id: request.request_id || request.headers["X-Request-Id"]
      }.merge(build_optional_error_fields(error, error_code))
    }
  end

  def build_optional_error_fields(error, error_code)
    fields = {}
    fields[:debug] = build_debug_info(error) if Rails.env.development?
    fields[:help_url] = error_help_url(error_code) if error_help_url(error_code)
    fields[:retry_after] = error.retry_after if error.respond_to?(:retry_after)
    fields
  end

  def build_debug_info(error)
    {
      class: error.class.name,
      backtrace: error.backtrace&.first(5)
    }
  end

  def log_error(error, level: :error)
    context = build_error_context(error)
    Rails.logger.public_send(level, "Error occurred: #{error.message}. Context: #{context.to_json}")
    notify_error_tracker(error, context) if should_notify_error?(error)
  end

  def build_error_context(error)
    context = build_request_context.merge(build_error_details(error))
    backtrace = error.backtrace
    context[:backtrace] = backtrace&.first(10) if backtrace
    context
  end

  def build_request_context
    {
      request_id: request.request_id,
      request_path: request.path,
      request_method: request.method,
      remote_ip: request.remote_ip,
      user_agent: request.user_agent,
      params: filtered_params
    }
  end

  def build_error_details(error)
    {
      error_class: error.class.name,
      error_message: error.message
    }
  end

  def filtered_params
    params.to_unsafe_h.except(:controller, :action).slice(:url, :fields)
  end

  def error_help_url(error_code)
    case error_code
    when "VALIDATION_ERROR"
      "https://api.example.com/docs/errors#validation"
    when "SECURITY_ERROR"
      "https://api.example.com/docs/errors#security"
    when "NETWORK_ERROR"
      "https://api.example.com/docs/errors#network"
    when "RATE_LIMIT_ERROR"
      "https://api.example.com/docs/errors#rate-limit"
    end
  end

  def should_notify_error?(error)
    # Don't notify for client errors in production
    return false if Rails.env.production? && client_error?(error)

    # Always notify for security errors
    return true if error.is_a?(ScraperErrors::SecurityError)

    # Notify for server errors
    !client_error?(error)
  end

  def client_error?(error)
    error.is_a?(ScraperErrors::ValidationError) ||
      error.is_a?(ActionController::ParameterMissing)
  end

  def notify_error_tracker(_error, context)
    # Placeholder for external error tracking integration
    # Examples: Sentry, Rollbar, Honeybadger, etc.
    # Sentry.capture_exception(error, extra: context)
    Rails.logger.info("Error notification would be sent to tracking service: #{context.to_json}")
  end
end
