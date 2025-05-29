# frozen_string_literal: true

module RequestLogging
  extend ActiveSupport::Concern

  included do
    before_action :set_request_id
    before_action :log_request_start
    after_action :log_request_complete
  end

  private

  def set_request_id
    # Use existing request ID or generate a new one
    request.request_id ||= SecureRandom.uuid

    # Set it in response headers for client correlation
    response.headers["X-Request-ID"] = request.request_id
  end

  def log_request_start
    @request_start_time = Time.current

    Rails.logger.info("Request started: #{request_context.to_json}")
  end

  def log_request_complete
    duration = ((Time.current - @request_start_time) * 1000).round(2)

    context = request_context.merge(
      response_status: response.status,
      response_content_type: response.content_type,
      duration_ms: duration
    )

    # Add response size if available
    context[:response_size_bytes] = response.body.bytesize if response.body.present?

    # Log level based on response status
    level = case response.status
            when 200..299 then :info
            when 400..499 then :warn
            else :error
            end

    Rails.logger.public_send(level, "Request completed: #{context.to_json}")

    # Track performance metrics
    track_request_metrics(context) if defined?(StatsD)
  end

  def request_context
    {
      request_id: request.request_id,
      method: request.method,
      path: request.path,
      remote_ip: request.remote_ip,
      user_agent: request.user_agent,
      params: filtered_request_params,
      timestamp: Time.current.iso8601
    }
  end

  def filtered_request_params
    # Only include relevant params, exclude Rails internal params
    params.to_unsafe_h.except(:controller, :action, :format).slice(:url, :fields)
  end

  def track_request_metrics(context)
    # Placeholder for metrics tracking
    # Examples: StatsD, Prometheus, CloudWatch
    # StatsD.timing("api.request.duration", context[:duration_ms])
    # StatsD.increment("api.request.status.#{context[:response_status]}")
  end
end
