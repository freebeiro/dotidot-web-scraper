# Testing Strategy Rules - Dotidot Web Scraper Challenge

## 🎯 Test Framework Setup Checklist

### RSpec Configuration
- [ ] **Add rspec-rails gem** to development/test groups
- [ ] **Run rails generate rspec:install** for initial setup
- [ ] **Configure spec_helper.rb** with basic settings
- [ ] **Configure rails_helper.rb** for Rails integration
- [ ] **Set up test database** configuration

### Essential Testing Gems
- [ ] **rspec-rails** (~> 6.0) - Core testing framework
- [ ] **factory_bot_rails** - Test data generation
- [ ] **faker** - Realistic fake data
- [ ] **shoulda-matchers** - Additional matchers for validations
- [ ] **webmock** - HTTP request stubbing

### RSpec Configuration Example
```ruby
# Gemfile
group :development, :test do
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'shoulda-matchers'
  gem 'webmock'
end

# spec/rails_helper.rb
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
```

## 🏭 Factory Bot Setup Checklist

### Factory Design Principles
- [ ] **One factory per model** with minimal valid attributes
- [ ] **Use traits** for variations (invalid, with_associations, etc.)
- [ ] **Use sequences** for unique values
- [ ] **Use build over create** when persistence not needed
- [ ] **Keep factories simple** and focused

### Web Scraper Factories
- [ ] **ScrapeRequest factory** with valid URL and fields
- [ ] **ScrapeResult factory** with cached data
- [ ] **Traits for different scenarios** (invalid_url, rate_limited, etc.)
- [ ] **Use Faker** for realistic test data
- [ ] **Avoid unnecessary associations**

### Factory Examples
```ruby
# spec/factories/scrape_requests.rb
FactoryBot.define do
  factory :scrape_request do
    sequence(:url) { |n| "https://example#{n}.com" }
    fields { { title: 'h1', description: 'p' } }
    
    trait :invalid_url do
      url { 'not-a-valid-url' }
    end
    
    trait :with_meta_fields do
      fields { { meta: ['description', 'keywords'] } }
    end
    
    trait :rate_limited do
      url { 'https://rate-limited-site.com' }
    end
  end
end

# spec/factories/scrape_results.rb
FactoryBot.define do
  factory :scrape_result do
    url_hash { Digest::SHA256.hexdigest(url) }
    sequence(:url) { |n| "https://example#{n}.com" }
    scraped_data { { title: 'Sample Title', description: 'Sample Description' } }
    status { 'completed' }
    
    trait :cached do
      status { 'cached' }
    end
    
    trait :failed do
      status { 'failed' }
      scraped_data { nil }
    end
  end
end
```

## 🧪 Unit Testing Checklist

### Model Testing Strategy
- [ ] **Test all validations** (presence, format, uniqueness)
- [ ] **Test all associations** (belongs_to, has_many)
- [ ] **Test custom methods** and business logic
- [ ] **Test scopes** and class methods
- [ ] **Test edge cases** and error conditions

### Service Object Testing
- [ ] **Test happy path** with valid inputs
- [ ] **Test error cases** with invalid inputs
- [ ] **Test edge cases** (empty data, malformed responses)
- [ ] **Mock external dependencies** (HTTP requests)
- [ ] **Test return value structure**

### Service Testing Example
```ruby
# spec/services/web_scraper_service_spec.rb
RSpec.describe WebScraperService do
  describe '.call' do
    let(:url) { 'https://example.com' }
    let(:fields) { { title: 'h1', description: 'p' } }
    
    context 'when scraping succeeds' do
      before do
        stub_request(:get, url)
          .to_return(body: '<h1>Test Title</h1><p>Test Description</p>')
      end
      
      it 'returns extracted data' do
        result = described_class.call(url, fields)
        
        expect(result[:data]).to include(
          title: 'Test Title',
          description: 'Test Description'
        )
        expect(result[:cached]).to be false
      end
    end
    
    context 'when URL is invalid' do
      let(:url) { 'not-a-valid-url' }
      
      it 'raises validation error' do
        expect {
          described_class.call(url, fields)
        }.to raise_error(ValidationError, /Invalid URL/)
      end
    end
  end
end
```

## 🌐 Request Testing Checklist

### API Endpoint Testing
- [ ] **Test all HTTP methods** (GET, POST)
- [ ] **Test success responses** (200 status, correct JSON)
- [ ] **Test error responses** (400, 422, 429, 500 status codes)
- [ ] **Test request validation** (missing params, invalid format)
- [ ] **Test response format** consistency

### Request Spec Structure
- [ ] **Organize by endpoint** (GET /data, POST /data)
- [ ] **Use shared examples** for common behavior
- [ ] **Test both success and failure paths**
- [ ] **Verify response headers** (Content-Type, status)
- [ ] **Test request/response cycle** completely

### Request Spec Examples
```ruby
# spec/requests/data_spec.rb
RSpec.describe 'Data API', type: :request do
  describe 'GET /data' do
    context 'with valid parameters' do
      let(:params) do
        {
          url: 'https://example.com',
          fields: { title: 'h1', description: 'p' }.to_json
        }
      end
      
      before do
        stub_request(:get, 'https://example.com')
          .to_return(body: '<h1>Test</h1><p>Description</p>')
      end
      
      it 'returns scraped data' do
        get '/data', params: params
        
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')
        
        json_response = JSON.parse(response.body)
        expect(json_response).to include('title', 'description')
      end
    end
    
    context 'with missing URL parameter' do
      it 'returns bad request error' do
        get '/data', params: { fields: '{}' }
        
        expect(response).to have_http_status(:bad_request)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Missing')
      end
    end
  end
  
  describe 'POST /data' do
    let(:valid_params) do
      {
        url: 'https://example.com',
        fields: { title: 'h1' }
      }
    end
    
    context 'with valid JSON body' do
      before do
        stub_request(:get, 'https://example.com')
          .to_return(body: '<h1>Test Title</h1>')
      end
      
      it 'processes JSON request' do
        post '/data', 
             params: valid_params.to_json,
             headers: { 'Content-Type' => 'application/json' }
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['title']).to eq('Test Title')
      end
    end
  end
end
```

## 🔄 Integration Testing Checklist

### End-to-End Testing
- [ ] **Test complete workflows** (request to response)
- [ ] **Test error handling** across all layers
- [ ] **Test caching behavior** (cache hits/misses)
- [ ] **Test rate limiting** functionality
- [ ] **Test background job processing**

### Shared Examples Usage
- [ ] **Create shared examples** for common API behavior
- [ ] **Test error response formats** consistently
- [ ] **Validate JSON response structure**
- [ ] **Test security measures** (rate limiting, validation)
- [ ] **DRY up repetitive test code**

### Shared Examples Implementation
```ruby
# spec/support/shared_examples/api_responses.rb
RSpec.shared_examples 'a successful API response' do
  it 'returns 200 status' do
    expect(response).to have_http_status(:ok)
  end
  
  it 'returns JSON content type' do
    expect(response.content_type).to include('application/json')
  end
  
  it 'returns valid JSON' do
    expect { JSON.parse(response.body) }.not_to raise_error
  end
end

RSpec.shared_examples 'an error API response' do |status_code|
  it "returns #{status_code} status" do
    expect(response).to have_http_status(status_code)
  end
  
  it 'returns error in JSON format' do
    json_response = JSON.parse(response.body)
    expect(json_response).to have_key('error')
    expect(json_response['error']).to be_present
  end
end

# Usage in tests
RSpec.describe 'Data API' do
  context 'successful request' do
    before { get '/data', params: valid_params }
    
    it_behaves_like 'a successful API response'
  end
  
  context 'invalid request' do
    before { get '/data', params: invalid_params }
    
    it_behaves_like 'an error API response', :bad_request
  end
end
```

## 🎭 Test Doubles & Mocking Checklist

### HTTP Request Mocking
- [ ] **Use WebMock** to stub external HTTP requests
- [ ] **Stub all external calls** in tests
- [ ] **Return realistic responses** in stubs
- [ ] **Test both success and failure responses**
- [ ] **Verify request details** (headers, body) when needed

### Mocking Best Practices
- [ ] **Mock external dependencies only**
- [ ] **Don't mock internal methods** of class under test
- [ ] **Use realistic stub data**
- [ ] **Reset mocks between tests**
- [ ] **Verify important interactions**

### Mocking Examples
```ruby
# spec/support/webmock_helpers.rb
module WebMockHelpers
  def stub_successful_scrape(url, response_body)
    stub_request(:get, url)
      .to_return(
        status: 200,
        body: response_body,
        headers: { 'Content-Type' => 'text/html' }
      )
  end
  
  def stub_failed_scrape(url, status: 500)
    stub_request(:get, url)
      .to_return(status: status, body: 'Error')
  end
  
  def stub_timeout_scrape(url)
    stub_request(:get, url).to_timeout
  end
end

# spec/rails_helper.rb
RSpec.configure do |config|
  config.include WebMockHelpers
end

# Usage in tests
RSpec.describe WebScraperService do
  it 'handles timeouts gracefully' do
    stub_timeout_scrape('https://slow-site.com')
    
    expect {
      described_class.call('https://slow-site.com', { title: 'h1' })
    }.to raise_error(TimeoutError)
  end
end
```

## 📊 Test Coverage & Quality Checklist

### Coverage Goals
- [ ] **Aim for 90%+ coverage** on critical paths
- [ ] **Test all public methods**
- [ ] **Cover all error conditions**
- [ ] **Test edge cases** and boundary conditions
- [ ] **Focus on meaningful tests** over just coverage

### Test Quality Indicators
- [ ] **Tests are readable** and well-named
- [ ] **Tests are isolated** (no dependencies between tests)
- [ ] **Tests are fast** (under 0.1 seconds each)
- [ ] **Tests are deterministic** (consistent results)
- [ ] **Tests fail for right reasons**

### Performance Testing
- [ ] **Use build over create** when possible
- [ ] **Avoid unnecessary database hits**
- [ ] **Use build_stubbed** for objects not needing persistence
- [ ] **Profile slow tests** and optimize
- [ ] **Run tests in parallel** if needed

```ruby
# Performance optimization examples
RSpec.describe User do
  # ✅ GOOD - Fast, no database hit
  it 'validates email format' do
    user = build(:user, email: 'invalid-email')
    expect(user).not_to be_valid
  end
  
  # ❌ BAD - Unnecessary database persistence
  it 'validates email format' do
    user = create(:user, email: 'invalid-email')
    expect(user).not_to be_valid
  end
end
```

## 🛡️ Security Testing Checklist

### Security Test Coverage
- [ ] **Test input validation** with malicious inputs
- [ ] **Test rate limiting** with high request volumes
- [ ] **Test authentication** and authorization
- [ ] **Test CSRF protection** if applicable
- [ ] **Test SQL injection prevention**

### Security Test Examples
```ruby
# spec/requests/security_spec.rb
RSpec.describe 'Security', type: :request do
  describe 'input validation' do
    it 'blocks malicious URLs' do
      post '/data', 
           params: { url: 'file:///etc/passwd', fields: '{}' }.to_json,
           headers: { 'Content-Type' => 'application/json' }
      
      expect(response).to have_http_status(:unprocessable_entity)
      
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to include('Invalid URL')
    end
  end
  
  describe 'rate limiting' do
    it 'enforces rate limits' do
      21.times do
        get '/data', params: { url: 'https://example.com', fields: '{}' }
      end
      
      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
```

## 🚀 Test Organization Checklist

### File Structure
- [ ] **Mirror app structure** in spec directory
- [ ] **Use descriptive file names** (ending in _spec.rb)
- [ ] **Organize by feature** and functionality
- [ ] **Keep test files focused** on single class/module
- [ ] **Use support directory** for shared code

### Test Structure Best Practices
- [ ] **Use descriptive describe blocks**
- [ ] **Use context for different scenarios**
- [ ] **One expectation per test** when possible
- [ ] **Clear test names** that describe behavior
- [ ] **Arrange-Act-Assert pattern**

### Test Organization Example
```ruby
RSpec.describe WebScraperService do
  describe '.call' do
    let(:url) { 'https://example.com' }
    let(:fields) { { title: 'h1' } }
    
    context 'when scraping a valid webpage' do
      before { stub_successful_scrape(url, '<h1>Title</h1>') }
      
      it 'returns extracted data' do
        result = described_class.call(url, fields)
        expect(result[:data][:title]).to eq('Title')
      end
      
      it 'marks result as not cached' do
        result = described_class.call(url, fields)
        expect(result[:cached]).to be false
      end
    end
    
    context 'when URL is invalid' do
      let(:url) { 'invalid-url' }
      
      it 'raises validation error' do
        expect {
          described_class.call(url, fields)
        }.to raise_error(ValidationError)
      end
    end
  end
end
```

---

## ✅ Testing Implementation Checklist

### Before Writing Tests
- [ ] Understand the behavior to test
- [ ] Identify all scenarios (happy path, edge cases, errors)
- [ ] Set up necessary test data (factories)
- [ ] Plan mocking strategy for external dependencies

### During Test Writing
- [ ] Write failing test first (red-green-refactor)
- [ ] Use descriptive test names
- [ ] Keep tests simple and focused
- [ ] Mock external dependencies properly
- [ ] Test one thing at a time

### After Test Implementation
- [ ] All tests pass consistently
- [ ] Tests are fast (full suite under 30 seconds)
- [ ] Coverage meets targets (90%+)
- [ ] Tests document expected behavior
- [ ] Tests catch real bugs

## 🚨 Test Quality Enforcement (CRITICAL)

### Mandatory Testing Workflow
```bash
# BEFORE any code changes
bundle exec rspec                    # Baseline - should be 100% passing

# DURING development (run frequently)
bundle exec rspec spec/specific/     # Test specific areas you're changing

# BEFORE committing (non-negotiable)
bundle exec rspec                    # MUST be 100% passing, 0 failures
bundle exec rubocop                  # MUST be 0 violations

# Emergency: If tests are broken
bundle exec rspec --fail-fast        # Stop on first failure
bundle exec rspec spec/file_spec.rb  # Fix one file at a time
```

### Test Failure Recovery Protocol
When you have multiple failing tests:

1. **Don't panic-fix everything at once**
2. **Create backup**: `cp -r spec spec_backup_$(date +%Y%m%d_%H%M%S)`  
3. **Fix incrementally by service/file**:
   ```bash
   bundle exec rspec spec/services/http_client_service_spec.rb
   bundle exec rspec spec/services/html_parser_service_spec.rb
   bundle exec rspec spec/controllers/
   bundle exec rspec spec/requests/
   ```
4. **Run full suite after each fix**: `bundle exec rspec`
5. **Remove backup when done**: `rm -rf spec_backup_*`

### Automated Testing Setup
```bash
# Git pre-commit hook (add to .git/hooks/pre-commit)
#!/bin/sh
echo "🧪 Running test suite..."
bundle exec rspec
if [ $? -ne 0 ]; then
  echo "❌ TESTS FAILED - Cannot commit with failing tests"
  echo "Fix all failing tests before committing"
  exit 1
fi
echo "✅ All tests passing - commit approved"
```

### Test Maintenance Rules
- [ ] **Run tests before ANY commit** - Zero tolerance for failing tests
- [ ] **Fix tests immediately** when they break - Don't accumulate tech debt
- [ ] **Add tests for new features** - No untested code in main branch
- [ ] **Update tests when refactoring** - Keep tests in sync with code
- [ ] **Remove obsolete tests** - Don't keep dead test code

### Emergency Situations
If you find 50+ failing tests:
1. **STOP coding new features**
2. **Focus ONLY on fixing tests**  
3. **Get to 0 failures before any new work**
4. **Root cause analysis** - How did this happen?
5. **Update workflow** to prevent recurrence

**Remember: Good tests are your safety net - invest in them like your application depends on it!**

**🚨 ZERO TOLERANCE POLICY: Never commit, push, or merge with failing tests or rubocop violations!**