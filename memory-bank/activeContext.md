# Active Context - Dotidot Web Scraper

## 🎯 Current Focus

**Active Phase**: Foundation Setup In Progress  
**Current Step**: Step 5 - HTTP Client Service  
**Priority**: Create HTTP client for fetching web pages safely

## 📋 HTTP Client Service - Focused Rules

### 🎯 RELEVANT RULES (5 Total)

1. **Service Object Design (Code Quality Rule #2)**
   - Single responsibility: HTTP fetching only
   - .call class method pattern for stateless operations
   - Return consistent data structure {body:, status:, headers:}
   - Proper error handling with custom exceptions
   - Private methods for internal logic

2. **HTTP Client Performance (Performance Rule #4)**
   - Use HTTP.rb for best performance
   - Set reasonable timeouts (connect: 5s, read: 15s)
   - Implement connection pooling and persistent connections
   - Handle response streaming for large pages
   - Retry logic with exponential backoff (max 3 retries)

3. **HTTP Request Mocking (Testing Rule #5)**
   - Use WebMock to stub all external HTTP requests
   - Test both success and failure responses
   - Mock timeouts and network errors
   - Create realistic stub responses
   - Verify request headers and parameters

4. **Input Validation & Security (Security Rule #1)**
   - Validate URL format and length (max 2048 chars)
   - Block localhost and internal IPs (SSRF prevention)
   - Only allow http/https schemes
   - Set appropriate User-Agent header
   - Handle SSL/TLS properly

5. **Error Handling Patterns (Code Quality Rule #5)**
   - Create custom exception hierarchy (NetworkError, TimeoutError, InvalidResponseError)
   - Log errors with context for debugging
   - Return user-friendly error messages
   - Handle partial failures gracefully
   - Implement circuit breaker pattern for repeated failures

### 🚫 IGNORED RULES (Not Relevant)

- **API Design Rules** - HTTP client is internal service, not REST endpoint
- **Database Performance Rules** - No database interaction in HTTP client
- **Background Processing Rules** - Synchronous HTTP client, no Sidekiq needed
- **Rails MVC Rules** - Service object, not controller/model
- **Meta Tag Extraction Rules** - Handled by separate extraction service
- **CSS Selector Rules** - Parsing done elsewhere
- **Rate Limiting Rules** - Implemented at controller level, not HTTP client
- **Git Workflow Rules** - Development process, not implementation concern

## 📋 Immediate Context

### **What We're Building Right Now:**
- HTTP client service with timeout configuration
- Proper User-Agent and error handling
- Retry logic with exponential backoff
- WebMock testing for HTTP scenarios

### **Success Criteria for Current Step:**
- [ ] HttpClientService with timeout configuration
- [ ] Add proper User-Agent headers
- [ ] Implement retry logic with exponential backoff
- [ ] Create tests using WebMock for various scenarios
- [ ] Handle timeouts, errors, and retries correctly

### **Testing Requirements:**
- **Automated**: RSpec tests with WebMock for HTTP scenarios
- **Manual**: Rails console testing with real URLs

## 🧠 Key Decisions for This Step

### **Core Gem Choices:**
- **Nokogiri** - Robust HTML parsing
- **HTTP.rb** - Fast, clean HTTP client
- **Redis** - Caching and session storage
- **Sidekiq** - Background job processing

### **Testing Gem Additions:**
- **WebMock** - HTTP request stubbing
- **Shoulda-matchers** - Enhanced RSpec matchers
- **Faker** - Realistic test data (already added)
- **FactoryBot** - Test object generation (already added)

## 🔄 Implementation Context

### **Current Rule Focus:**
**When implementing Step 2, focus on:**
- **Code Quality**: Gemfile organization in proper groups
- **Testing Strategy**: Testing gem configuration in rails_helper
- **Web Scraping**: Core gems needed (nokogiri, http)
- **Performance**: Redis and background processing setup

### **Rules to Ignore for Now:**
- Detailed security patterns (not handling input yet)
- API design patterns (no API endpoints yet)
- Complex performance optimization (basic gems only)
- Advanced web scraping techniques (core setup only)

## 📊 Progress Context

### **Step 2 Completion:**
✅ Essential gems added and configured successfully  
✅ Nokogiri, HTTP.rb, Redis, Sidekiq gems installed  
✅ WebMock and Shoulda-matchers testing gems added  
✅ RSpec configured with new testing helpers  
✅ All gems load correctly in Rails console  
✅ Proper commit created with gem organization

### **Implementation Progress:**
- **Phase 1 (Steps 1-8)**: Foundation Setup - **25.0% complete** (2/8)
- **Phase 2 (Steps 9-14)**: API Implementation - **0% complete**  
- **Phase 3 (Steps 15-19)**: Performance & Caching - **0% complete**
- **Phase 4 (Steps 20-24)**: Quality & Documentation - **0% complete**
- **Phase 5 (Steps 25-28)**: Final Polish - **0% complete**

## ⚡ Next Actions

### **Immediate Task (Step 3):**
1. **Live Rule Filtering** - Identify relevant rules for error handling
2. **ScraperErrors Module** - Create lib/scraper_errors.rb file
3. **Exception Classes** - ValidationError, SecurityError, NetworkError
4. **Rails Configuration** - Ensure lib directory autoloading
5. **RSpec Tests** - Test exception inheritance and messaging
6. **Testing & Validation** - Verify exceptions work in console
7. **Commit** - `feat: add custom exception hierarchy for error handling`

### **Following Steps (Phase 1):**
- **Step 4**: URL validation service with SSRF protection
- **Step 5**: HTTP client service with retry logic
- **Step 6**: Basic HTML parser service
- **Step 7**: CSS extraction strategy

## 🎯 Quality Focus

### **Code Quality Standards:**
- Follow Rails naming conventions consistently
- Keep files organized in proper Rails directories
- Ensure all configuration is environment-appropriate
- Write meaningful commit messages

### **Testing Standards:**
- Set up RSpec with proper configuration
- Configure FactoryBot for test data generation
- Ensure test database is properly configured
- Verify all testing infrastructure works

## 🚨 Critical Reminders

### **AI Workflow Rules:**
- **Analyze existing files** before creating new ones (none exist yet for Step 1)
- **Build modular components** for reusability
- **No temporary scripts** or throwaway files
- **Clean up unused code** after any changes

### **Security Mindset:**
- Even basic setup should consider security implications
- Database configuration should be secure
- No sensitive data in version control
- Proper environment variable handling

---

**Focus**: Create clean exception hierarchy for proper error handling throughout the application.

**Next Update**: After completing Step 3 - Basic Error Classes
