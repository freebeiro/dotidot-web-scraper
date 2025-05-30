# frozen_string_literal: true

# Configure Rack::Attack for rate limiting and security protection
# Protects the web scraper API from abuse and overuse

# Use Redis for storing rate limit counters
Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
  namespace: "rack_attack"
)

# Block suspicious requests (SAFELIST before blocking)
# Allow local development traffic
Rack::Attack.safelist("allow-localhost") do |req|
  # Explicitly allow localhost/development in development environment
  Rails.env.development? && %w[127.0.0.1 ::1].include?(req.ip)
end

# Allow health checks
Rack::Attack.safelist("allow-health-checks") do |req|
  req.path == "/up"
end

# THROTTLING RULES
# Based on security rules: 20 requests/minute per IP, 10 requests/minute per domain

# Per-IP rate limiting for all scraping endpoints
Rack::Attack.throttle("requests by ip", limit: 20, period: 1.minute) do |req|
  req.ip if req.path.start_with?("/api/v1/data")
end

# Per-domain rate limiting (prevent hammering same domain)
Rack::Attack.throttle("requests by domain", limit: 10, period: 1.minute) do |req|
  if req.path.start_with?("/api/v1/data")
    # Extract domain from URL parameter (for both GET and POST)
    domain = extract_domain_from_request(req)
    "#{req.ip}:#{domain}" if domain
  end
end

# Global rate limiting (prevent overall API abuse)
Rack::Attack.throttle("requests globally", limit: 100, period: 1.minute) do |req|
  "global" if req.path.start_with?("/api/v1/data")
end

# BLOCKING RULES
# Block requests that are clearly malicious

# Block requests with suspicious patterns in URL parameters
Rack::Attack.blocklist("block malicious urls") do |req|
  if req.path.start_with?("/api/v1/data")
    url_param = req.params["url"] || extract_url_from_post_body(req)
    
    if url_param
      # Block obvious SSRF attempts
      malicious_patterns = [
        /localhost/i,
        /127\.0\.0\.1/,
        /0\.0\.0\.0/,
        /192\.168\./,
        /10\.\d+\./,
        /172\.1[6-9]\./,
        /172\.2[0-9]\./,
        /172\.3[0-1]\./,
        /file:\/\//i,
        /javascript:/i,
        /data:/i
      ]
      
      malicious_patterns.any? { |pattern| url_param.match?(pattern) }
    end
  end
end

# RATE LIMIT RESPONSE CONFIGURATION
# Customize response for rate limited requests
Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env["rack.attack.match_data"] || {}
  now = match_data[:epoch_time] || Time.now.to_i
  
  headers = {
    "Content-Type" => "application/json",
    "Retry-After" => match_data[:period].to_s,
    "X-RateLimit-Limit" => match_data[:limit].to_s,
    "X-RateLimit-Remaining" => "0",
    "X-RateLimit-Reset" => (now + (match_data[:period] - (now % match_data[:period]))).to_s
  }
  
  body = {
    success: false,
    error: "Rate limit exceeded. Please try again later.",
    retry_after: match_data[:period]
  }.to_json
  
  [429, headers, [body]]
end

# BLOCKED REQUEST RESPONSE
Rack::Attack.blocklisted_responder = lambda do |_request|
  [
    422, 
    { "Content-Type" => "application/json" },
    [{
      success: false,
      error: "Request blocked for security reasons"
    }.to_json]
  ]
end

# LOGGING AND MONITORING
# Log all rate limiting events for monitoring

ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
  request = payload[:request]
  
  case name
  when "throttle.rack.attack"
    Rails.logger.warn({
      event: "rate_limit_triggered",
      ip: request.ip,
      path: request.path,
      matched: request.env["rack.attack.matched"],
      match_type: request.env["rack.attack.match_type"],
      user_agent: request.user_agent,
      timestamp: Time.current.iso8601
    }.to_json)
    
  when "blocklist.rack.attack"
    Rails.logger.error({
      event: "request_blocked",
      ip: request.ip,
      path: request.path,
      matched: request.env["rack.attack.matched"],
      user_agent: request.user_agent,
      timestamp: Time.current.iso8601
    }.to_json)
  end
end

# HELPER METHODS
# Private methods for extracting domain information

def extract_domain_from_request(request)
  # Try GET parameters first
  url_param = request.params["url"]
  
  # Try POST body for JSON requests
  url_param ||= extract_url_from_post_body(request)
  
  return nil unless url_param
  
  begin
    uri = URI.parse(url_param)
    uri.host&.downcase
  rescue URI::InvalidURIError
    nil
  end
end

def extract_url_from_post_body(request)
  return nil unless request.post? && request.content_type&.include?("application/json")
  
  # Read body safely (it might have been read already)
  body = if request.body.respond_to?(:rewind)
           request.body.rewind
           request.body.read
         else
           request.body_stream&.read
         end
  
  return nil if body.nil? || body.empty?
  
  begin
    json_data = JSON.parse(body)
    json_data["url"]
  rescue JSON::ParserError
    nil
  ensure
    # Rewind the body for the application to read
    request.body.rewind if request.body.respond_to?(:rewind)
  end
end
