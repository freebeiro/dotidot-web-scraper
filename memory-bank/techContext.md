# Technical Context - Dotidot Web Scraper

## 🛠️ Technology Stack (Finalized)

### **Core Framework:**
- **Rails 7.1** (API mode) - Latest stable version for modern Rails practices
- **Ruby 3.1+** - Required for Rails 7.1 compatibility
- **PostgreSQL 14+** - Primary database for development and production
- **Puma** - Web server (Rails default)

### **Web Scraping & HTTP:**
- **Nokogiri** - HTML/XML parsing and CSS selector processing  
- **HTTP.rb** - Modern HTTP client (preferred over HTTParty for performance)
- **URI** - Ruby standard library for URL validation and parsing

### **Caching & Background Processing:**
- **Redis 6+** - Cache store and Sidekiq backend
- **Sidekiq 7.0** - Background job processing (matches Dotidot stack)
- **Rails.cache** - Application-level caching interface

### **Testing Framework:**
- **RSpec Rails 6.0** - Primary testing framework
- **FactoryBot Rails** - Test data generation
- **Faker** - Realistic fake data for tests
- **WebMock** - HTTP request stubbing for isolation
- **Shoulda Matchers** - Additional Rails-specific matchers

### **Security & Performance:**
- **Rack::Attack** - Rate limiting and throttling
- **Strong Parameters** - Rails input validation
- **Custom Validators** - SSRF protection and input sanitization

## 🏗️ Architecture Decisions

### **Service Object Pattern:**
All business logic encapsulated in service objects following the pattern:
```ruby
ServiceName.call(parameters) # Returns structured hash result
```

### **Error Handling Strategy:**
Custom exception hierarchy for clear error categorization:
```ruby
ScraperErrors::ValidationError
ScraperErrors::SecurityError  
ScraperErrors::NetworkError
ScraperErrors::ParsingError
```

### **Caching Strategy:**
- Page-level caching for scraped HTML content
- TTL-based expiration (1 hour default)
- Cache key generation from URL + field combination hash
- Cache status reporting in API responses

### **Testing Architecture:**
- Unit tests for service objects
- Integration tests for controller actions
- Request specs for API endpoints
- Factory-based test data generation
- WebMock for external HTTP request stubbing

## 🔧 Development Environment Setup

### **Required Software:**
- Ruby 3.1+ (via rbenv recommended)
- PostgreSQL 14+ (local installation or Docker)
- Redis 6+ (local installation or Docker)
- Bundler 2.3+

### **Development Commands:**
```bash
# Initial setup
rails new dotidot-web-scraper --api --database=postgresql
bundle install
rails db:create db:migrate RAILS_ENV=development
rails db:create db:migrate RAILS_ENV=test

# Testing
bundle exec rspec
bundle exec rspec spec/requests/ # API tests
bundle exec rspec spec/services/ # Service tests

# Development server
rails server # Port 3000
sidekiq # Background jobs (when implemented)
```

## 📊 Performance Targets

### **Response Time Goals:**
- API endpoints: < 200ms for cached responses
- Scraping operations: < 2 seconds for typical web pages
- Background jobs: Process within 30 seconds

### **Concurrency Targets:**
- Rate limiting: 20 requests/minute per IP
- Sidekiq workers: 5 concurrent workers
- Cache hit ratio: > 80% for repeated requests

## 🛡️ Security Configuration

### **Input Validation Requirements:**
- URL format validation (http/https schemes only)
- SSRF protection (block localhost, private IP ranges)
- CSS selector syntax validation
- Request payload size limits (100KB maximum)

### **Rate Limiting Rules:**
```ruby
# Rack::Attack configuration targets
throttle('requests/ip', limit: 20, period: 1.minute)
throttle('requests/domain', limit: 10, period: 1.minute)
```

## 🔄 Development Workflow

### **Code Organization:**
- `/app/services/` - Business logic service objects
- `/app/controllers/` - Thin controllers delegating to services
- `/lib/` - Custom exception classes and utilities
- `/spec/` - Comprehensive test coverage
- `/config/` - Application and environment configuration

### **Quality Standards:**
- RuboCop compliance for code style
- 90%+ test coverage with meaningful tests
- Service objects under 100 lines each
- Controllers under 50 lines each
- Comprehensive error handling at all levels

---

*This technical context provides the foundation for building a professional-grade Rails application suitable for enterprise environments processing billions of records.*
