# Security Patterns Rules - Dotidot Web Scraper Challenge

## 🛡️ URL Validation Checklist

### Basic URL Security
- [ ] **Check URL format** using URI.parse with error handling
- [ ] **Allow only http/https** schemes (reject file://, ftp://, javascript:)
- [ ] **Validate URL length** (maximum 2048 characters)
- [ ] **Block localhost** and internal IP addresses
- [ ] **Block private networks** (10.x.x.x, 172.16-31.x.x, 192.168.x.x)

### SSRF Prevention Rules
- [ ] **Block 127.0.0.1** and localhost variants
- [ ] **Block 0.0.0.0** and all zero addresses
- [ ] **Block metadata services** (169.254.169.254 for cloud)
- [ ] **Block internal domains** (.local, .internal)
- [ ] **Use allowlist approach** when possible

### URL Validation Implementation
```ruby
class UrlValidatorService
  ALLOWED_SCHEMES = %w[http https].freeze
  BLOCKED_IPS = %w[127.0.0.1 0.0.0.0 localhost].freeze
  PRIVATE_RANGES = %w[10.0.0.0/8 172.16.0.0/12 192.168.0.0/16].freeze
  MAX_URL_LENGTH = 2048

  def self.call(url)
    # Basic checks first
    raise SecurityError, "URL too long" if url.length > MAX_URL_LENGTH
    
    uri = URI.parse(url)
    raise SecurityError, "Invalid scheme" unless ALLOWED_SCHEMES.include?(uri.scheme)
    raise SecurityError, "Blocked host" if blocked_host?(uri.host)
    
    url
  rescue URI::InvalidURIError
    raise SecurityError, "Invalid URL format"
  end
end
```

## 🔍 Input Validation Checklist

### CSS Selector Security
- [ ] **Validate CSS syntax** using Nokogiri::CSS.parse
- [ ] **Limit selector length** (maximum 200 characters)
- [ ] **Block dangerous selectors** (script, style, meta patterns)
- [ ] **Sanitize selector input** before processing
- [ ] **Reject complex selectors** that could cause DoS

### JSON Parameter Validation
- [ ] **Validate JSON structure** with proper error handling
- [ ] **Limit JSON payload size** (maximum 10KB)
- [ ] **Check required fields** (url, fields)
- [ ] **Validate field count** (reasonable limits)
- [ ] **Sanitize all string inputs**

### Meta Fields Validation
- [ ] **Validate meta array structure**
- [ ] **Check meta tag names** against allowlist
- [ ] **Limit meta fields count** (maximum 20)
- [ ] **Sanitize meta tag names**

## 🚦 Rate Limiting Checklist

### Rate Limiting Strategy
- [ ] **Implement per-IP limits** (20 requests/minute)
- [ ] **Implement per-domain limits** (10 requests/minute to same domain)
- [ ] **Implement global limits** (100 requests/minute total)
- [ ] **Use Redis for rate limit storage**
- [ ] **Return 429 status** for rate limit violations

### Rate Limiting Implementation
```ruby
# Use Rack::Attack for rate limiting
class Application < Rails::Application
  config.middleware.use Rack::Attack
end

# In initializers/rack_attack.rb
Rack::Attack.throttle('requests by ip', limit: 20, period: 1.minute) do |request|
  request.ip if request.path == '/data'
end

Rack::Attack.throttle('requests by domain', limit: 10, period: 1.minute) do |request|
  if request.path == '/data'
    # Extract domain from URL parameter
    domain = extract_domain_from_request(request)
    "#{request.ip}:#{domain}"
  end
end
```

## 🔒 Request Security Checklist

### HTTP Security Headers
- [ ] **X-Frame-Options**: DENY or SAMEORIGIN
- [ ] **X-Content-Type-Options**: nosniff
- [ ] **X-XSS-Protection**: 0 (disabled for CSP)
- [ ] **Referrer-Policy**: strict-origin-when-cross-origin
- [ ] **Content-Security-Policy**: appropriate policy

### Request Validation
- [ ] **Validate Content-Type** for POST requests (application/json)
- [ ] **Check request method** (only GET and POST allowed)
- [ ] **Validate request size** (maximum 100KB)
- [ ] **Timeout long requests** (maximum 30 seconds)
- [ ] **Log security violations**

## 🛡️ Response Security Checklist

### Safe Response Handling
- [ ] **Never reflect user input** directly in responses
- [ ] **Escape all output** (Rails does this by default)
- [ ] **Set proper Content-Type** (application/json)
- [ ] **Include security headers** in all responses
- [ ] **Don't expose internal errors** to users

### Error Response Security
- [ ] **Generic error messages** for external users
- [ ] **Detailed logging** for internal debugging
- [ ] **No stack traces** in production responses
- [ ] **Consistent error format** across all endpoints
- [ ] **Proper HTTP status codes**

### Secure Error Response Example
```ruby
# ✅ GOOD - Generic message, detailed logging
rescue SecurityError => e
  Rails.logger.warn("Security violation: #{e.message} from #{request.ip}")
  render json: { error: "Invalid request", status: 422 }, status: :unprocessable_entity
end

# ❌ BAD - Exposes internal details
rescue SecurityError => e
  render json: { error: e.message, backtrace: e.backtrace }, status: 422
end
```

## 🔐 Data Protection Checklist

### Sensitive Data Handling
- [ ] **No credentials in logs** (filter sensitive parameters)
- [ ] **No database secrets** in error messages
- [ ] **Hash/encrypt stored data** if sensitive
- [ ] **Use environment variables** for secrets
- [ ] **Secure temporary files** if created

### Logging Security
- [ ] **Filter sensitive parameters** in Rails logs
- [ ] **Log security events** for monitoring
- [ ] **Don't log full URLs** (potential secrets in query params)
- [ ] **Use structured logging** for security events
- [ ] **Rotate logs regularly**

### Rails Logging Configuration
```ruby
# config/application.rb
config.filter_parameters += [
  :password, :password_confirmation, :secret, :token, :key,
  :url # Don't log URLs that might contain secrets
]

# Custom security logger
class SecurityLogger
  def self.log_violation(type, details, request)
    Rails.logger.warn({
      event: 'security_violation',
      type: type,
      ip: request.ip,
      user_agent: request.user_agent,
      details: details,
      timestamp: Time.current.iso8601
    }.to_json)
  end
end
```

## 🏗️ Application Security Checklist

### Rails Security Features
- [ ] **CSRF protection** enabled (protect_from_forgery)
- [ ] **Force SSL** in production (force_ssl)
- [ ] **Secure cookies** configuration
- [ ] **Strong parameters** for all inputs
- [ ] **SQL injection protection** (use ActiveRecord methods)

### Dependencies Security
- [ ] **Scan for vulnerabilities** with bundler-audit
- [ ] **Keep gems updated** to latest secure versions
- [ ] **Review new dependencies** before adding
- [ ] **Monitor security advisories**

## 🚨 Monitoring & Alerting Checklist

### Security Monitoring
- [ ] **Monitor rate limit violations**
- [ ] **Alert on unusual request patterns**
- [ ] **Track failed validation attempts**
- [ ] **Log all security exceptions**
- [ ] **Monitor resource usage** (CPU, memory)

### Security Metrics to Track
- [ ] **Requests per minute** by IP
- [ ] **Invalid URL attempts** count
- [ ] **Rate limit violations** count  
- [ ] **Security exceptions** count
- [ ] **Response time degradation**

## 🛡️ Web Scraping Security Checklist

### Responsible Scraping
- [ ] **Respect robots.txt** (check if required)
- [ ] **Implement delays** between requests
- [ ] **Use appropriate User-Agent** header
- [ ] **Handle rate limiting gracefully**
- [ ] **Don't overload target servers**

### Target Website Protection
- [ ] **Check website's terms of service**
- [ ] **Implement polite crawling delays**
- [ ] **Monitor target site response times**
- [ ] **Back off on errors** (exponential backoff)
- [ ] **Respect HTTP caching headers**

## ✅ Security Testing Checklist

### Test All Security Measures
- [ ] **Test URL validation** with malicious URLs
- [ ] **Test CSS selector injection** attempts
- [ ] **Test rate limiting** with high request volumes
- [ ] **Test error handling** with invalid inputs
- [ ] **Test SSRF prevention** with internal URLs

### Security Test Examples
```ruby
describe 'URL validation security' do
  it 'blocks localhost URLs' do
    expect {
      UrlValidatorService.call('http://localhost:3000')
    }.to raise_error(SecurityError, /Blocked host/)
  end
  
  it 'blocks internal IP addresses' do
    expect {
      UrlValidatorService.call('http://192.168.1.1')  
    }.to raise_error(SecurityError, /Blocked host/)
  end
  
  it 'blocks metadata service URLs' do
    expect {
      UrlValidatorService.call('http://169.254.169.254/metadata')
    }.to raise_error(SecurityError, /Blocked host/)
  end
end
```

## 🔥 Emergency Response Checklist

### Security Incident Response
- [ ] **Document the incident** immediately
- [ ] **Identify affected systems** and data
- [ ] **Implement immediate containment**
- [ ] **Notify stakeholders** as required
- [ ] **Plan remediation steps**

### Post-Incident Actions
- [ ] **Review security logs** for timeline
- [ ] **Update security measures** based on learnings
- [ ] **Test improved defenses**
- [ ] **Document lessons learned**

---

## ✅ Pre-Deployment Security Check

### Final Security Verification
- [ ] All input validation working correctly
- [ ] Rate limiting configured and tested
- [ ] Error handling doesn't expose internal details
- [ ] Security headers properly configured
- [ ] Logging captures security events
- [ ] Dependencies scanned for vulnerabilities

### Production Security Configuration
- [ ] Environment variables for all secrets
- [ ] SSL/TLS properly configured
- [ ] Security monitoring enabled
- [ ] Backup and recovery procedures tested
- [ ] Incident response plan documented

**Remember: Security is not optional - it's a core requirement for professional web applications!**