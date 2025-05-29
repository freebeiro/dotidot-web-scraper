# frozen_string_literal: true

# Provides standardized logging capabilities for service objects with performance tracking
module ServiceLogging
  extend ActiveSupport::Concern

  private

  def log_service_call(service_name, input)
    start_time = Time.current
    request_id = Thread.current[:request_id]

    Rails.logger.info("Service call started", {
                        service: service_name,
                        request_id: request_id,
                        input: sanitize_input(input)
                      })

    begin
      result = yield
      log_completion(service_name, request_id, start_time, true)
      result
    rescue => e
      log_completion(service_name, request_id, start_time, false, e)
      raise
    end
  end

  def log_completion(service_name, request_id, start_time, success, error = nil)
    duration = calculate_duration(start_time)

    if success
      Rails.logger.info("Service call completed", build_completion_context(service_name, request_id, duration, true))
    else
      Rails.logger.error("Service call failed",
                         build_completion_context(service_name, request_id, duration, false, error))
    end
  end

  def calculate_duration(start_time)
    ((Time.current - start_time) * 1000).round(2)
  end

  def build_completion_context(service_name, request_id, duration, success, error = nil)
    context = {
      service: service_name,
      request_id: request_id,
      duration_ms: duration,
      success: success
    }

    if error
      context[:error_class] = error.class.name
      context[:error_message] = error.message
    end

    context
  end

  def sanitize_input(input)
    case input
    when String
      # Truncate long strings (like HTML content)
      input.length > 200 ? "#{input[0..200]}..." : input
    when Hash
      # Only include safe keys
      input.slice(:url, :fields, :selector, :timeout)
    else
      input.to_s
    end
  end

  def with_request_context
    # Store request ID in thread-local storage for access in services
    current_thread = Thread.current
    current_thread[:request_id] = defined?(request) ? request&.request_id : nil
    yield
  ensure
    current_thread[:request_id] = nil
  end
end
