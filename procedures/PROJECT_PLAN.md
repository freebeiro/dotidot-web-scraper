# Dotidot Web Scraper - PROJECT PLAN

## 🎯 Project Overview

**Goal**: Build a Ruby on Rails REST API web scraper for the Dotidot Backend Developer technical challenge
**Timeline**: Few days (interview project)
**Approach**: Start simple, testable, iterate with professional practices
**Submission**: GitHub repository with detailed README

## 🏗️ Development Strategy

### **Core Principle: Very Small Steps**
- Each step should take 15-30 minutes maximum
- Each step should be fully testable
- Each step should follow our established rules
- Commit after each completed step

### **MANDATORY PROCESS FOR EVERY STEP**

#### **📋 Step A: Live Rule Filtering (MANDATORY)**
**Before implementing any step, we MUST:**
1. **Review all 8 rule files** and identify which rules apply to this specific task
2. **Create a focused checklist** of only the relevant rules for this step
3. **Ignore irrelevant rules** to avoid overwhelming complexity
4. **Document the filtered rules** for this step

#### **🛠️ Step B: Implementation**
- Implement the task following ONLY the filtered rules from Step A
- Keep it simple and focused on the specific deliverable

#### **🧪 Step C: Testing & Validation**
- [ ] **Automated tests pass** (RSpec where applicable)
- [ ] **Manual testing works** (curl commands or Rails console)
- [ ] **Filtered rules compliance** verified
- [ ] **Step deliverable achieved**

#### **📝 Step D: Documentation & Commit**
- [ ] **Document what was done** and how to test it
- [ ] **Commit with proper message format** from rules/git_workflow_rules.md
- [ ] **Ready for next step**

---

## 📋 PHASE 1: Foundation Setup (Steps 1-8)

### **Step 1: Rails Application Setup**
**Time**: 15 minutes | **Files**: 3-4 | **Tests**: Manual + Automated

#### **📋 Step 1A: Rule Filtering (MANDATORY)**
**Relevant Rules for Rails Setup:**
- **Git Workflow**: Commit message format, initial project structure
- **Code Quality**: File organization, Rails conventions
- **Testing Strategy**: RSpec setup and configuration
- **Performance**: Basic Rails configuration for efficiency

**Filtered Checklist:**
- [ ] Use proper commit message format: `chore: initialize Rails API application with RSpec`
- [ ] Follow Rails file structure conventions
- [ ] Set up RSpec correctly with rails_helper configuration
- [ ] Configure database for development/test environments
- [ ] Ensure application starts without errors

**Ignored Rules:** API design (no API yet), Security patterns (no user input yet), Web scraping (no scraping yet), detailed performance optimization (basic setup only)

#### **🛠️ Step 1B: Implementation**
**What**: Initialize Rails API application with basic configuration
- [ ] `rails new dotidot-web-scraper --api --database=postgresql`
- [ ] Update Gemfile with essential gems (rspec-rails, factory_bot_rails)
- [ ] Configure database.yml for development/test
- [ ] Run `rails generate rspec:install`
- [ ] Configure basic RSpec settings in rails_helper.rb

#### **🧪 Step 1C: Testing & Validation**
**Automated Tests:**
- [ ] `bundle exec rspec` runs without errors (even with 0 tests)
- [ ] `rails db:create RAILS_ENV=test` succeeds

**Manual Testing:**
- [ ] `rails server` starts successfully
- [ ] Visit `http://localhost:3000` shows Rails API welcome page or 404 (expected for API)
- [ ] `rails console` starts without errors

**Testing Commands:**
```bash
# Test server starts
rails server
# In another terminal
curl http://localhost:3000
# Should return JSON error or 404, not HTML error

# Test database
rails db:create RAILS_ENV=test

# Test RSpec
bundle exec rspec
```

#### **📝 Step 1D: Documentation & Commit**
**Deliverable**: Basic Rails API app that starts successfully with RSpec configured
**Commit**: `chore: initialize Rails API application with RSpec setup`

**Documentation**: 
- Rails 7.1 API application created
- PostgreSQL configured for development/test
- RSpec testing framework installed and configured
- Application starts successfully on port 3000

---

### **Step 2: Essential Gems Setup**
**Time**: 20 minutes | **Files**: 2-3 | **Tests**: Manual + Automated

#### **📋 Step 2A: Rule Filtering (MANDATORY)**
**Relevant Rules for Gem Setup:**
- **Git Workflow**: Proper commit message format
- **Code Quality**: Gemfile organization, dependency management
- **Testing Strategy**: Testing gem configuration
- **Web Scraping**: Core gems needed (nokogiri, http)
- **Performance**: Redis and background processing gems

**Filtered Checklist:**
- [ ] Organize Gemfile with proper groups (development, test, production)
- [ ] Add only essential gems needed for next steps
- [ ] Configure testing gems properly in rails_helper.rb
- [ ] Use proper commit message: `chore: add essential gems for web scraping and testing`
- [ ] Ensure bundle install completes successfully

**Ignored Rules:** Detailed security (not handling input yet), API design (no API endpoints yet), complex performance (basic gems only)

#### **🛠️ Step 2B: Implementation**
**What**: Add and configure core gems needed for web scraping
- [ ] Add gems to Gemfile: nokogiri, http, redis, sidekiq
- [ ] Add testing gems: factory_bot_rails, faker, webmock, shoulda-matchers
- [ ] Organize gems in proper groups (development, test, production)
- [ ] Run `bundle install`
- [ ] Configure basic RSpec settings in rails_helper.rb (FactoryBot, WebMock)

#### **🧪 Step 2C: Testing & Validation**
**Automated Tests:**
- [ ] `bundle exec rspec` runs without errors
- [ ] `bundle check` confirms all gems installed correctly

**Manual Testing:**
- [ ] `rails console` starts and can require gems:
```ruby
# In rails console
require 'nokogiri'
require 'http'
require 'redis'
# Should not raise errors
```

**Testing Commands:**
```bash
# Test gem installation
bundle check
bundle exec rspec

# Test gem loading in console
rails console
# Then in console:
# require 'nokogiri'
# require 'http'
# exit
```

#### **📝 Step 2D: Documentation & Commit**
**Deliverable**: All essential gems installed and configured
**Commit**: `chore: add essential gems for web scraping and testing`

**Documentation**:
- Core gems added: nokogiri, http, redis, sidekiq
- Testing gems configured: rspec-rails, factory_bot_rails, faker, webmock, shoulda-matchers
- RSpec configured with testing helpers
- All gems install and load correctly

---

### **Step 3: Basic Error Classes**
**Time**: 15 minutes | **Files**: 2 | **Tests**: 2

#### **🛠️ Step 3B: Implementation**
**What**: Create custom exception hierarchy for clear error handling
- [ ] Create `lib/scraper_errors.rb` with base exception classes
- [ ] Add ValidationError, SecurityError, NetworkError classes
- [ ] Create simple spec to test exception inheritance
- [ ] Configure Rails to autoload lib directory

#### **🧪 Step 3C: Testing & Validation**
**Automated Tests:**
- [ ] Exception classes can be instantiated with messages
- [ ] Exception inheritance works correctly

**Manual Testing:**
- [ ] `rails console` can instantiate exception classes
```ruby
# In rails console
ScraperErrors::ValidationError.new("test message")
```

**Deliverable**: Clean exception hierarchy ready for use
**Commit**: `feat: add custom exception hierarchy for error handling`

---

### **Step 4: URL Validation Service (Core Security)**
**Time**: 25 minutes | **Files**: 2 | **Tests**: 6+

#### **🛠️ Step 4B: Implementation**
**What**: Implement secure URL validation to prevent SSRF attacks
- [ ] Create `UrlValidatorService` class in `app/services/`
- [ ] Implement SSRF protection (block localhost, private IPs)
- [ ] Add URL format validation (http/https only)
- [ ] Create comprehensive RSpec tests for security scenarios
- [ ] Test with malicious URLs (localhost, private networks, invalid schemes)

#### **🧪 Step 4C: Testing & Validation**
**Automated Tests:**
- [ ] All security scenarios covered and blocked appropriately
- [ ] Valid URLs pass validation
- [ ] Invalid URLs raise appropriate errors

**Manual Testing:**
```ruby
# In rails console
UrlValidatorService.call('https://example.com') # Should work
UrlValidatorService.call('http://localhost') # Should raise error
```

**Deliverable**: Production-ready URL validator with security tests
**Commit**: `security: implement URL validation service with SSRF protection`

---

### **Step 5: HTTP Client Service**
**Time**: 20 minutes | **Files**: 2 | **Tests**: 4

#### **🛠️ Step 5B: Implementation**
**What**: Create HTTP client for fetching web pages safely
- [ ] Create `HttpClientService` with timeout configuration
- [ ] Add proper User-Agent and error handling
- [ ] Implement retry logic with exponential backoff
- [ ] Create tests using WebMock for various HTTP scenarios
- [ ] Test timeout handling and error responses

#### **🧪 Step 5C: Testing & Validation**
**Automated Tests:**
- [ ] HTTP client handles timeouts, errors, and retries correctly
- [ ] WebMock stubs work properly

**Manual Testing:**
```ruby
# In rails console (with internet connection)
HttpClientService.call('https://httpbin.org/get')
```

**Deliverable**: Reliable HTTP client with error handling
**Commit**: `feat: implement HTTP client service with retry logic`

---

### **Step 6: Basic HTML Parser Service**
**Time**: 15 minutes | **Files**: 2 | **Tests**: 3

#### **🛠️ Step 6B: Implementation**
**What**: Create Nokogiri wrapper for safe HTML parsing
- [ ] Create `HtmlParserService` using Nokogiri
- [ ] Add validation for malformed HTML
- [ ] Handle encoding issues gracefully
- [ ] Create tests for valid/invalid HTML parsing
- [ ] Test encoding handling

#### **🧪 Step 6C: Testing & Validation**
**Automated Tests:**
- [ ] Parser handles valid HTML, malformed HTML, and encoding issues

**Manual Testing:**
```ruby
# In rails console
HtmlParserService.call('<html><body><h1>Test</h1></body></html>')
```

**Deliverable**: Safe HTML parser with error handling
**Commit**: `feat: implement HTML parser service with Nokogiri`

---

### **Step 7: CSS Extraction Strategy**
**Time**: 25 minutes | **Files**: 2 | **Tests**: 5

#### **🛠️ Step 7B: Implementation**
**What**: Implement CSS selector-based data extraction
- [ ] Create `CssExtractionStrategy` class
- [ ] Implement safe CSS selector parsing and extraction
- [ ] Add text cleaning and normalization
- [ ] Create tests for various CSS selectors and edge cases
- [ ] Test with missing elements and invalid selectors

#### **🧪 Step 7C: Testing & Validation**
**Automated Tests:**
- [ ] CSS extraction works with various selectors and handles failures

**Manual Testing:**
```ruby
# In rails console
html = '<h1>Title</h1><p class="desc">Description</p>'
doc = Nokogiri::HTML(html)
CssExtractionStrategy.extract(doc, 'h1') # Should return "Title"
```

**Deliverable**: Robust CSS data extraction with comprehensive tests
**Commit**: `feat: implement CSS extraction strategy with text cleaning`

---

### **Step 8: Foundation Integration Test**
**Time**: 15 minutes | **Files**: 1 | **Tests**: 2

#### **🛠️ Step 8B: Implementation**
**What**: Integration test connecting all foundation services
- [ ] Create integration spec that chains services together
- [ ] Test: URL validation → HTTP fetch → HTML parse → CSS extract
- [ ] Use real HTML content in test for end-to-end validation
- [ ] Verify error propagation works correctly

#### **🧪 Step 8C: Testing & Validation**
**Automated Tests:**
- [ ] Complete flow from URL to extracted data works

**Manual Testing:**
```ruby
# In rails console - full integration test
url = 'https://httpbin.org/html'
validated_url = UrlValidatorService.call(url)
html = HttpClientService.call(validated_url)
doc = HtmlParserService.call(html)
result = CssExtractionStrategy.extract(doc, 'h1')
```

**Deliverable**: Working integration of all foundation services
**Commit**: `test: add integration test for foundation services`

---

## 📋 PHASE 2: Core API Implementation (Steps 9-14)

### **Step 9: Basic Rails Controller**
**Time**: 20 minutes | **Files**: 2 | **Tests**: 3

#### **🛠️ Step 9B: Implementation**
**What**: Create skinny controller following Rails best practices
- [ ] Generate `DataController` with index action
- [ ] Implement basic parameter extraction (url, fields)
- [ ] Add strong parameters and basic validation
- [ ] Create request specs for parameter validation
- [ ] Test successful parameter extraction and error cases

**Deliverable**: Clean controller that extracts and validates parameters
**Commit**: `feat: implement basic data controller with parameter validation`

---

### **Step 10: Web Scraper Service Integration**
**Time**: 25 minutes | **Files**: 2 | **Tests**: 4

#### **🛠️ Step 10B: Implementation**
**What**: Main service that orchestrates all scraping operations
- [ ] Create `WebScraperService` that chains all existing services
- [ ] Use dependency injection pattern for testability
- [ ] Return structured response (data, cached, timestamp)
- [ ] Create comprehensive service tests
- [ ] Test integration with all foundation services

**Deliverable**: Complete scraping service with proper error handling
**Commit**: `feat: implement web scraper service with service integration`

---

### **Step 11: GET /data Endpoint**
**Time**: 20 minutes | **Files**: 1 | **Tests**: 4

#### **🛠️ Step 11B: Implementation**
**What**: Implement GET endpoint with query parameters
- [ ] Connect controller to WebScraperService
- [ ] Handle JSON parsing for fields parameter
- [ ] Implement proper error response formatting
- [ ] Create request specs for GET endpoint
- [ ] Test with real scraping scenarios using WebMock

**Deliverable**: Working GET /data endpoint with proper JSON responses
**Commit**: `feat: implement GET /data endpoint with query parameters`

---

### **Step 12: POST /data Endpoint**
**Time**: 15 minutes | **Files**: 1 | **Tests**: 3

#### **🛠️ Step 12B: Implementation**
**What**: Implement POST endpoint with JSON body
- [ ] Add create action to DataController
- [ ] Parse JSON body with proper error handling
- [ ] Use same WebScraperService for consistency
- [ ] Create request specs for POST endpoint
- [ ] Test JSON body validation and processing

**Deliverable**: Working POST /data endpoint with JSON body processing
**Commit**: `feat: implement POST /data endpoint with JSON body support`

---

### **Step 13: Meta Tag Extraction**
**Time**: 25 minutes | **Files**: 2 | **Tests**: 5

#### **🛠️ Step 13B: Implementation**
**What**: Add meta tag extraction capability to meet challenge requirements
- [ ] Create `MetaExtractionStrategy` class
- [ ] Support common meta tags (description, keywords, og:*, twitter:*)
- [ ] Handle meta field arrays in request format
- [ ] Update WebScraperService to use both CSS and meta strategies
- [ ] Create comprehensive tests for meta tag extraction

**Deliverable**: Complete meta tag extraction matching challenge spec
**Commit**: `feat: implement meta tag extraction strategy`

---

### **Step 14: End-to-End API Testing**
**Time**: 20 minutes | **Files**: 1 | **Tests**: 4

#### **🛠️ Step 14B: Implementation**
**What**: Comprehensive API testing with real-world scenarios
- [ ] Create E2E request specs using challenge examples
- [ ] Test both GET and POST with CSS selectors and meta tags
- [ ] Use realistic HTML content for testing
- [ ] Verify response format matches challenge requirements
- [ ] Test error scenarios end-to-end

**Deliverable**: Complete API functionality matching challenge requirements
**Commit**: `test: add end-to-end API tests with challenge examples`

---

## 📋 PHASE 3: Performance & Caching (Steps 15-19)

### **Step 15: Redis Configuration**
**Time**: 15 minutes | **Files**: 2 | **Tests**: 1

#### **🛠️ Step 15B: Implementation**
**What**: Set up Redis for caching with proper configuration
- [ ] Configure Rails cache store to use Redis
- [ ] Add Redis configuration for development/test environments
- [ ] Create Redis connection test
- [ ] Update application.rb with cache configuration
- [ ] Test Redis connectivity in specs

**Deliverable**: Rails application configured to use Redis for caching
**Commit**: `chore: configure Redis cache store for performance`

---

### **Step 16: Page Cache Service**
**Time**: 25 minutes | **Files**: 2 | **Tests**: 5

#### **🛠️ Step 16B: Implementation**
**What**: Implement intelligent caching for scraped pages
- [ ] Create `PageCacheService` with TTL configuration
- [ ] Generate cache keys from URL and field combinations
- [ ] Implement cache get/set with expiration
- [ ] Add cache invalidation methods
- [ ] Create comprehensive caching tests

**Deliverable**: Working page cache with proper key generation
**Commit**: `feat: implement page cache service with TTL configuration`

---

### **Step 17: Cache Integration**
**Time**: 20 minutes | **Files**: 1 | **Tests**: 4

#### **🛠️ Step 17B: Implementation**
**What**: Integrate caching into WebScraperService
- [ ] Update WebScraperService to check cache first
- [ ] Cache successful scraping results
- [ ] Return cache status in response (cached: true/false)
- [ ] Handle cache misses gracefully
- [ ] Test cache hits and misses in service specs

**Deliverable**: WebScraperService with intelligent caching
**Commit**: `feat: integrate page caching into web scraper service`

---

### **Step 18: Rate Limiting Setup**
**Time**: 20 minutes | **Files**: 2 | **Tests**: 3

#### **🛠️ Step 18B: Implementation**
**What**: Implement rate limiting for security and politeness
- [ ] Add rack-attack gem for rate limiting
- [ ] Configure per-IP and per-domain rate limits
- [ ] Set up Redis for rate limiting storage
- [ ] Create rate limiting tests
- [ ] Test rate limit responses (429 status)

**Deliverable**: API with proper rate limiting configuration
**Commit**: `security: implement rate limiting with rack-attack`

---

### **Step 19: Performance Monitoring**
**Time**: 15 minutes | **Files**: 2 | **Tests**: 2

#### **🛠️ Step 19B: Implementation**
**What**: Add basic performance monitoring and logging
- [ ] Create performance tracking middleware/service
- [ ] Log response times and cache performance
- [ ] Add request ID tracking
- [ ] Monitor memory usage for scraping operations
- [ ] Test performance logging functionality

**Deliverable**: Basic performance monitoring and logging
**Commit**: `feat: add performance monitoring and request tracking`

---

## 📋 PHASE 4: Quality & Documentation (Steps 20-24)

### **Step 20: Background Processing Setup**
**Time**: 20 minutes | **Files**: 3 | **Tests**: 2

#### **🛠️ Step 20B: Implementation**
**What**: Set up Sidekiq for background processing (optional enhancement)
- [ ] Configure Sidekiq with Redis
- [ ] Create basic job for heavy scraping operations
- [ ] Add job retry configuration
- [ ] Create job specs with proper testing
- [ ] Test job execution and error handling

**Deliverable**: Background job processing capability
**Commit**: `feat: implement background processing with Sidekiq`

---

### **Step 21: Security Hardening**
**Time**: 20 minutes | **Files**: 2 | **Tests**: 4

#### **🛠️ Step 21B: Implementation**
**What**: Additional security measures and testing
- [ ] Add security headers configuration
- [ ] Implement request size limits
- [ ] Add comprehensive security testing
- [ ] Test for common web vulnerabilities
- [ ] Verify all input validation is working

**Deliverable**: Hardened application with comprehensive security
**Commit**: `security: add comprehensive security hardening`

---

### **Step 22: API Documentation**
**Time**: 25 minutes | **Files**: 2 | **Tests**: 0

#### **🛠️ Step 22B: Implementation**
**What**: Create comprehensive API documentation
- [ ] Document all endpoints with examples
- [ ] Create curl examples for testing
- [ ] Document error responses and status codes
- [ ] Add API versioning information
- [ ] Create API documentation in README

**Deliverable**: Complete API documentation with examples
**Commit**: `docs: add comprehensive API documentation`

---

### **Step 23: Error Handling & Logging**
**Time**: 20 minutes | **Files**: 2 | **Tests**: 3

#### **🛠️ Step 23B: Implementation**
**What**: Comprehensive error handling and logging
- [ ] Implement structured logging for all operations
- [ ] Add detailed error context and debugging info
- [ ] Create error tracking and alerting
- [ ] Test error scenarios comprehensively
- [ ] Verify error responses are user-friendly

**Deliverable**: Production-ready error handling and logging
**Commit**: `feat: implement comprehensive error handling and logging`

---

### **Step 24: Production Configuration**
**Time**: 15 minutes | **Files**: 3 | **Tests**: 1

#### **🛠️ Step 24B: Implementation**
**What**: Configure application for production deployment
- [ ] Configure production environment settings
- [ ] Set up environment variable management
- [ ] Configure database pooling and connections
- [ ] Add health check endpoint
- [ ] Test production configuration

**Deliverable**: Production-ready application configuration
**Commit**: `chore: configure application for production deployment`

---

## 📋 PHASE 5: Final Polish & Testing (Steps 25-28)

### **Step 25: Comprehensive Test Suite**
**Time**: 30 minutes | **Files**: 2 | **Tests**: 10+

#### **🛠️ Step 25B: Implementation**
**What**: Ensure >90% test coverage with meaningful tests
- [ ] Review test coverage with SimpleCov
- [ ] Add missing test scenarios
- [ ] Ensure all edge cases are covered
- [ ] Verify all error conditions are tested
- [ ] Clean up any redundant or weak tests

**Deliverable**: Comprehensive test suite with excellent coverage
**Commit**: `test: achieve comprehensive test coverage`

---

### **Step 26: Code Quality Review**
**Time**: 25 minutes | **Files**: Multiple | **Tests**: 0

#### **🛠️ Step 26B: Implementation**
**What**: Final code quality pass following all rules
- [ ] Run RuboCop and fix any violations
- [ ] Review all files for naming conventions
- [ ] Ensure SOLID principles are followed
- [ ] Verify service objects are properly designed
- [ ] Check file sizes and complexity

**Deliverable**: Clean, professional codebase following all rules
**Commit**: `refactor: final code quality improvements`

---

### **Step 27: README & Documentation**
**Time**: 30 minutes | **Files**: 2 | **Tests**: 0

#### **🛠️ Step 27B: Implementation**
**What**: Create comprehensive README and documentation
- [ ] Write project overview and purpose
- [ ] Add installation and setup instructions
- [ ] Document API usage with examples
- [ ] Include testing and development guide
- [ ] Add architecture and design decisions

**Deliverable**: Professional README suitable for technical review
**Commit**: `docs: create comprehensive README and documentation`

---

### **Step 28: Final Integration & Deployment**
**Time**: 20 minutes | **Files**: 2 | **Tests**: 2

#### **🛠️ Step 28B: Implementation**
**What**: Final testing and deployment preparation
- [ ] Run complete test suite and verify all pass
- [ ] Test application end-to-end manually
- [ ] Verify all challenge requirements are met
- [ ] Create deployment script or Docker configuration
- [ ] Final commit and tag for submission

**Deliverable**: Complete, tested application ready for submission
**Commit**: `chore: final preparation for submission`

---

## 🎯 Success Criteria

### **Technical Requirements Met**
- [ ] GET /data endpoint with URL and fields parameters ✅
- [ ] POST /data endpoint with JSON body ✅
- [ ] CSS selector extraction working ✅
- [ ] Meta tag extraction working ✅
- [ ] Caching optimization implemented ✅
- [ ] Security measures in place ✅

### **Quality Standards Met**
- [ ] >90% test coverage with RSpec ✅
- [ ] All security rules followed ✅
- [ ] Clean architecture with service objects ✅
- [ ] Professional Git commit history ✅
- [ ] Comprehensive documentation ✅
- [ ] Production-ready error handling ✅

### **Interview Readiness**
- [ ] Code demonstrates Rails expertise ✅
- [ ] Security consciousness evident ✅
- [ ] Performance optimization implemented ✅
- [ ] Professional development practices ✅
- [ ] Ready for architecture discussion ✅

---

## 🚀 Next Steps After Plan

1. **Save this PROJECT_PLAN.md** to your project root
2. **Confirm you're ready** to start Step 1
3. **Follow each step exactly** - small, testable increments
4. **Commit after each step** with proper commit messages
5. **Review progress** after each phase

**Ready Status**: Comprehensive plan created, rules established, ready for implementation! 🎉