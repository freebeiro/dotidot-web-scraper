# frozen_string_literal: true

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
      duration = ((Time.current - start_time) * 1000).round(2)

      Rails.logger.info("Service call completed", {
                          service: service_name,
                          request_id: request_id,
                          duration_ms: duration,
                          success: true
                        })

      result
    rescue => e
      duration = ((Time.current - start_time) * 1000).round(2)

      Rails.logger.error("Service call failed", {
                           service: service_name,
                           request_id: request_id,
                           duration_ms: duration,
                           error_class: e.class.name,
                           error_message: e.message,
                           success: false
                         })

      raise
    end
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
    Thread.current[:request_id] = defined?(request) ? request&.request_id : nil
    yield
  ensure
    Thread.current[:request_id] = nil
  end
end
