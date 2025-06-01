# Dotidot Web Scraper

A professional Ruby on Rails REST API for web scraping, built as a technical demonstration for the Dotidot Backend Developer challenge.

## 🎯 Project Overview

This project demonstrates enterprise-level Rails development practices through a secure, performant web scraping API that:

- **Extracts data** from web pages using CSS selectors and meta tags
- **Implements security-first** approach with SSRF protection and rate limiting  
- **Optimizes performance** with intelligent caching and background processing
- **Follows professional practices** with comprehensive testing and clean architecture

## 🏗️ Architecture

### **Technology Stack**
- **Rails 7.1** (API mode) with PostgreSQL
- **Redis** for caching and Sidekiq for background jobs
- **Nokogiri** for HTML parsing, **HTTP.rb** for HTTP requests
- **RSpec** with FactoryBot for comprehensive testing

### **Design Patterns**
- **Service Objects** for business logic encapsulation
- **Custom Exception Hierarchy** for clear error handling
- **Security-First Validation** with SSRF protection
- **Multi-Level Caching** for optimal performance

## 📋 API Endpoints

### **POST /api/v1/data**
Extract data using JSON body with CSS selectors:
```bash
curl -X POST http://localhost:3005/api/v1/data \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com","fields":{"title":"h1","description":"meta[name=\"description\"]"}}'
```

**Response:**
```json
{"title":"Example Domain","description":"This domain is for examples","cached":false}
```

### **GET /api/v1/data**
Extract data using URL parameters:
```bash
curl "http://localhost:3005/api/v1/data?url=https://example.com&fields[title]=h1"
```

## 🚀 Getting Started

### **Prerequisites**
- Ruby 3.1+
- PostgreSQL 14+
- Redis 6+
- Bundler 2.3+

### **Installation**
```bash
# Clone the repository
git clone https://github.com/yourusername/dotidot-web-scraper.git
cd dotidot-web-scraper

# Install dependencies
bundle install

# Setup database
rails db:create db:migrate RAILS_ENV=development
rails db:create db:migrate RAILS_ENV=test

# Start Redis (if not running)
redis-server

# Run tests
bundle exec rspec

# Start the server (default port 3000, or specify port)
rails server
# Or on specific port:
rails server -p 3005
```

## 🧪 Testing & Quality Assurance

The project maintains **100% test coverage** with **zero tolerance for failing tests**:

```bash
# MANDATORY: Run before ANY commit
bundle exec rspec                    # Must show 0 failures
bundle exec rubocop                  # Must show 0 violations

# Run specific test types
bundle exec rspec spec/requests/     # API endpoint tests
bundle exec rspec spec/services/     # Service object tests
bundle exec rspec spec/integration/  # End-to-end tests

# Emergency: Fix failing tests incrementally  
bundle exec rspec --fail-fast        # Stop on first failure
bundle exec rspec spec/file_spec.rb  # Fix one file at a time
```

### **Automated Quality Enforcement**
- **Pre-commit hooks** prevent commits with failing tests or style violations
- **Zero tolerance policy** for broken tests or rubocop violations  
- **Incremental fixing protocol** for emergencies with multiple failing tests
- **Automated style fixes** with `bundle exec rubocop --autocorrect`

**🚨 CRITICAL: Never commit, push, or merge with failing tests!**

## 🛡️ Security Features

- **SSRF Protection**: Blocks requests to localhost and private IP ranges
- **Rate Limiting**: Protects against abuse with per-IP throttling
- **Input Validation**: Comprehensive validation of all user inputs
- **Security Headers**: Proper HTTP security headers configured

## ⚡ Performance Features

- **Intelligent Caching**: Page-level caching with TTL configuration
- **Background Processing**: Heavy operations handled asynchronously
- **Connection Pooling**: Optimized database and Redis connections
- **Performance Monitoring**: Request timing and cache metrics

## 📖 Documentation

- **[PROJECT_PLAN.md](PROJECT_PLAN.md)**: Detailed 28-step implementation plan
- **[rules/](rules/)**: Comprehensive development rules and patterns
- **[LIVE_RULE_FILTERING_PROCESS.md](LIVE_RULE_FILTERING_PROCESS.md)**: Development process documentation
- **[AI_HANDOFF_INSTRUCTIONS.md](AI_HANDOFF_INSTRUCTIONS.md)**: Instructions for project continuation

## 🎯 Challenge Requirements

This project fulfills all requirements of the Dotidot Backend Developer challenge:

- ✅ **CSS Selector Extraction** with flexible field mapping (`{"title": "h1"}`)
- ✅ **Meta Tag Extraction** supporting complex selectors (`{"description": "meta[name=\"description\"]"}`)
- ✅ **Caching Optimization** Redis-based with `cached: true/false` indicators
- ✅ **Error Handling** with proper HTTP status codes and descriptive messages
- ✅ **Security Features** SSRF protection, URL validation, and input sanitization
- ✅ **Performance Optimization** Sub-second responses with caching (440ms → 1ms)

## 🚀 Deployment

Ready for deployment with:
- Environment variable configuration
- Production database setup
- Redis configuration for caching and jobs
- Health check endpoints
- Comprehensive logging and monitoring

## 🤝 Development Process

This project follows strict professional development practices:

- **Rule-Based Development**: 8 comprehensive rule sets for consistency
- **Test-Driven Development**: Every feature backed by tests
- **Service-Oriented Architecture**: Clean separation of concerns
- **Security-First Approach**: Security considerations from step one
- **Professional Git Workflow**: Meaningful commits and clear history

## 📊 Project Status

**Current Phase**: ✅ **COMPLETE** - Fully Implemented and Tested
**API Status**: ✅ All endpoints working with comprehensive error handling
**Testing**: ✅ 256 passing tests with caching, security, and integration coverage
**Production Ready**: ✅ Redis caching, retry logic, and security features active

---

*Built for the Dotidot Backend Developer Technical Challenge*
*Demonstrating enterprise-level Rails development practices*