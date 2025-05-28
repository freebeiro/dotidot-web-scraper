# System Patterns - Dotidot Web Scraper

## 🏗️ Architectural Patterns

### **Service Object Pattern**
**Primary pattern for business logic encapsulation:**

```ruby
# Standard service object interface
class ServiceName
  def self.call(*args)
    new(*args).call
  end
  
  def initialize(*args)
    # Setup instance variables
  end
  
  def call
    # Main business logic
    # Return structured hash: { data: ..., status: ..., errors: ... }
  end
  
  private
  
  # Helper methods
end
```

**Usage Examples:**
- `WebScraperService.call(url, fields)`
- `UrlValidatorService.call(url)`
- `DataExtractionService.call(html, fields)`

### **Error Handling Pattern**
**Consistent exception hierarchy:**

```ruby
module ScraperErrors
  class BaseError < StandardError
    attr_reader :context
    
    def initialize(message, context = {})
      super(message)
      @context = context
    end
  end
  
  class ValidationError < BaseError; end
  class SecurityError < BaseError; end
  class NetworkError < BaseError; end
  class ParsingError < BaseError; end
end
```

### **Controller Pattern**
**Thin controllers delegating to services:**

```ruby
class ApiController < ApplicationController
  def action_name
    # 1. Extract parameters
    # 2. Validate basic input
    # 3. Call service object
    # 4. Handle service response
    # 5. Return JSON response
  rescue SpecificError => e
    render json: { error: e.message, status: 422 }, status: :unprocessable_entity
  end
end
```

## 🔧 Technical Patterns

### **Validation Pattern**
**Multi-layer input validation:**

```ruby
# 1. Controller level - basic parameter presence
# 2. Service level - business logic validation  
# 3. Security level - SSRF and injection prevention
# 4. Format level - data type and structure validation
```

### **Caching Pattern**
**Intelligent caching with TTL:**

```ruby
class CacheService
  def self.get_or_set(key, ttl: 1.hour)
    Rails.cache.fetch(key, expires_in: ttl) do
      yield if block_given?
    end
  end
end
```

### **HTTP Client Pattern**
**Robust HTTP handling with retries:**

```ruby
class HttpClientService
  RETRY_ATTEMPTS = 3
  TIMEOUT_SECONDS = 15
  
  def self.call(url)
    # HTTP client with timeout, retries, and error handling
  end
end
```

## 🧪 Testing Patterns

### **Service Object Testing**
**Comprehensive service testing pattern:**

```ruby
RSpec.describe ServiceName do
  describe '.call' do
    let(:valid_input) { build(:factory_name) }
    
    context 'with valid input' do
      it 'returns expected result' do
        result = described_class.call(valid_input)
        expect(result[:data]).to include(expected_keys)
      end
    end
    
    context 'with invalid input' do
      it 'raises appropriate error' do
        expect {
          described_class.call(invalid_input)
        }.to raise_error(SpecificError)
      end
    end
  end
end
```

### **Request Testing Pattern**
**API endpoint testing with WebMock:**

```ruby
RSpec.describe 'API Endpoint', type: :request do
  describe 'GET /endpoint' do
    before do
      stub_request(:get, external_url)
        .to_return(status: 200, body: mock_response)
    end
    
    it 'returns expected JSON' do
      get '/endpoint', params: valid_params
      
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include(expected_data)
    end
  end
end
```

### **Factory Pattern**
**Consistent test data generation:**

```ruby
FactoryBot.define do
  factory :model_name do
    attribute { Faker::Internet.url }
    
    trait :invalid do
      attribute { 'invalid-value' }
    end
    
    trait :with_association do
      association :related_model
    end
  end
end
```

## 🔒 Security Patterns

### **Input Validation Pattern**
**Layered security validation:**

```ruby
# 1. URL validation with SSRF protection
# 2. Parameter sanitization
# 3. Size limit enforcement
# 4. Rate limiting per IP/domain
# 5. Content type validation
```

### **SSRF Prevention Pattern**
**Comprehensive host blocking:**

```ruby
class UrlValidatorService
  BLOCKED_HOSTS = %w[localhost 127.0.0.1 0.0.0.0].freeze
  PRIVATE_RANGES = %w[10.0.0.0/8 172.16.0.0/12 192.168.0.0/16].freeze
  
  def self.safe_url?(url)
    # Implementation blocks internal networks and localhost
  end
end
```

## 📊 Performance Patterns

### **Caching Strategy Pattern**
**Multi-level caching approach:**

```ruby
# 1. Page-level caching for scraped content
# 2. Fragment caching for expensive operations
# 3. Query caching for database operations
# 4. HTTP caching headers for API responses
```

### **Background Processing Pattern**
**Async job processing:**

```ruby
class ProcessingJob < ApplicationJob
  queue_as :scraping
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  
  def perform(*args)
    # Heavy processing logic
  end
end
```

## 🔄 Data Flow Patterns

### **Request Processing Flow**
```
Request → Controller → Parameter Validation → Service Object → 
Business Logic → External HTTP → HTML Parsing → Data Extraction → 
Cache Storage → Response Formatting → JSON Response
```

### **Error Handling Flow**
```
Error Occurrence → Exception Classification → Context Logging → 
User-Friendly Message → HTTP Status Code → JSON Error Response
```

### **Caching Flow**
```
Request → Cache Key Generation → Cache Check → 
[Cache Hit: Return Cached Data] OR [Cache Miss: Process Request → Cache Result] → 
Response with Cache Status
```

## 🎯 Integration Patterns

### **Service Integration Pattern**
**Chainable service objects:**

```ruby
result = UrlValidatorService.call(url)
html = HttpClientService.call(result[:validated_url])
data = DataExtractionService.call(html, fields)
cached_result = CacheService.store(cache_key, data)
```

### **Error Propagation Pattern**
**Consistent error handling across services:**

```ruby
begin
  service_result = SomeService.call(params)
rescue ServiceError => e
  Rails.logger.error("Service failed: #{e.message}", e.context)
  raise ApiError.new(user_friendly_message, { original_error: e })
end
```

---

**These patterns ensure consistency, maintainability, and scalability across the entire application while following Rails best practices and enterprise-grade development standards.**
