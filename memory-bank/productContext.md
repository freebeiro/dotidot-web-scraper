# Product Context - Dotidot Web Scraper

## 🎯 Product Purpose

**Primary Goal**: Demonstrate professional Rails development capabilities through a secure, performant web scraping REST API

**Target Audience**: Dotidot technical team evaluating:
- Rails expertise and modern development practices
- Security consciousness for enterprise-scale applications  
- Performance optimization skills for high-traffic systems
- Professional testing and development methodologies

## 📋 Product Requirements

### **Functional Requirements:**
- **GET /data endpoint** accepting URL and fields parameters
- **POST /data endpoint** accepting JSON body with URL and fields
- **CSS Selector Extraction** from specified HTML elements
- **Meta Tag Extraction** supporting arrays of meta field names
- **Response Format** returning extracted data as JSON key-value pairs

### **Non-Functional Requirements:**
- **Security**: SSRF protection, input validation, rate limiting
- **Performance**: Intelligent caching, background processing capability
- **Reliability**: Comprehensive error handling and graceful degradation
- **Maintainability**: Clean architecture following SOLID principles
- **Testability**: >90% test coverage with meaningful tests

## 🏗️ Architecture Principles

### **Design Philosophy:**
- **Security First**: Every input validated, SSRF protection mandatory
- **Performance Conscious**: Caching and optimization from the start
- **Test-Driven**: Every feature backed by comprehensive tests
- **Service-Oriented**: Clean separation of concerns using service objects
- **Professional Standards**: Enterprise-level code quality and practices

### **Scalability Considerations:**
- **Horizontal Scaling**: Stateless design ready for multiple instances
- **Background Processing**: Heavy operations handled asynchronously
- **Caching Strategy**: Multi-level caching for performance
- **Rate Limiting**: Protect against abuse and ensure fair usage
- **Monitoring**: Performance and security event tracking

## 🎯 Success Metrics

### **Technical Excellence:**
- Clean, readable, maintainable code
- Comprehensive security measures implemented
- Optimal performance with intelligent caching  
- Professional testing practices demonstrated
- Proper error handling and logging

### **Business Value:**
- Demonstrates capability to work with Dotidot's technology stack
- Shows ability to build secure applications handling sensitive data
- Exhibits performance consciousness suitable for billion-record scale
- Reflects professional development practices for team environments

## 🔄 Usage Scenarios

### **Primary Use Case - CSS Extraction:**
```json
GET /data?url=https://example.com&fields={"title":"h1","price":".price"}
Response: {"title":"Product Name","price":"$19.99"}
```

### **Secondary Use Case - Meta Tag Extraction:**
```json
POST /data
Body: {"url":"https://example.com","fields":{"meta":["description","keywords"]}}
Response: {"meta":{"description":"...","keywords":"..."}}
```

### **Performance Use Case - Caching:**
- Repeated requests to same URL should return cached results
- Cache should be intelligent about field combinations
- Cache status should be indicated in responses

## 🎊 Product Vision

**Short-term**: Complete technical challenge demonstrating Rails expertise, security awareness, and performance consciousness

**Long-term**: Foundation for scalable web scraping platform capable of handling enterprise-scale data extraction requirements with security, performance, and reliability suitable for Dotidot's billion-record processing environment

---

*This product serves as both a technical demonstration and a foundation for understanding enterprise-scale development practices in the context of data processing and web scraping applications.*
