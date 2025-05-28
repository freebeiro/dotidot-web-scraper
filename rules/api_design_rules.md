# API Design Rules - Dotidot Web Scraper Challenge

## 🎯 REST Endpoint Design Checklist

### URL Structure Rules
- [ ] **Use nouns, not verbs** in URLs (`/data` not `/getData`)
- [ ] **Use HTTP methods** to indicate actions (GET, POST, PUT, DELETE)
- [ ] **Keep URLs simple** and predictable
- [ ] **Use consistent naming** throughout API
- [ ] **No nested resources** deeper than 2 levels

### Required Endpoints for Challenge
- [ ] `GET /data` - Scrape data with query parameters
- [ ] `POST /data` - Scrape data with JSON body
- [ ] `GET /health` - Health check endpoint (optional)

### URL Examples
```bash
# ✅ GOOD
GET /data?url=example.com&fields={"title":"h1"}
POST /data

# ❌ BAD  
GET /scrapeData
POST /extractFromWebsite
```

## 📤 Request Format Checklist

### Query Parameters (GET)
- [ ] **Accept URL parameter** as string
- [ ] **Accept fields parameter** as JSON string
- [ ] **Validate all parameters** before processing
- [ ] **Return 400** for missing required parameters

### JSON Body (POST)
- [ ] **Accept Content-Type**: `application/json`
- [ ] **Require url field** in JSON body
- [ ] **Require fields object** in JSON body
- [ ] **Validate JSON structure** before processing

### Example Request Formats
```bash
# GET with query parameters
GET /data?url=https://example.com&fields={"title":"h1","price":".price"}

# POST with JSON body
POST /data
Content-Type: application/json
{
  "url": "https://example.com",
  "fields": {
    "title": "h1",
    "price": ".price"
  }
}
```

## 📥 Response Format Checklist

### Success Response Structure
- [ ] **Always return JSON** with proper Content-Type
- [ ] **Include scraped data** as key-value pairs
- [ ] **Use consistent field names** from request
- [ ] **Return 200 status** for successful scraping

### Success Response Example
```json
{
  "title": "Product Name",
  "price": "$19.99",
  "description": "Product description text"
}
```

### Meta Fields Response
- [ ] **Return meta object** for meta field requests
- [ ] **Include requested meta tags** as key-value pairs
- [ ] **Handle missing meta tags** gracefully (return null)

### Meta Response Example
```json
{
  "meta": {
    "keywords": "product, shopping, deals",
    "twitter:image": "https://example.com/image.jpg"
  }
}
```

## ❌ Error Handling Checklist

### HTTP Status Codes to Use
- [ ] **200** - Successful scraping
- [ ] **400** - Bad request (missing/invalid parameters)
- [ ] **422** - Validation failed (invalid URL, CSS selectors)
- [ ] **429** - Rate limit exceeded
- [ ] **500** - Internal server error
- [ ] **503** - Service unavailable

### Error Response Format
- [ ] **Always return JSON** for errors
- [ ] **Include error field** with descriptive message
- [ ] **Include status field** with HTTP status code
- [ ] **Use consistent error structure** across all endpoints

### Error Response Examples
```json
// 400 Bad Request
{
  "error": "Missing required parameter: url",
  "status": 400
}

// 422 Validation Error
{
  "error": "Invalid URL format: not-a-valid-url",
  "status": 422
}

// 429 Rate Limit
{
  "error": "Rate limit exceeded. Please try again later.",
  "status": 429
}
```

## 🛡️ Input Validation Checklist

### URL Validation Rules
- [ ] **Check URL format** (valid URI structure)
- [ ] **Require http/https** schemes only
- [ ] **Block localhost** and internal IPs
- [ ] **Limit URL length** (max 2048 characters)
- [ ] **Return 422** for invalid URLs

### Fields Validation Rules
- [ ] **Validate JSON structure** for fields parameter
- [ ] **Check CSS selector syntax** for regular fields
- [ ] **Validate meta array** for meta field requests
- [ ] **Limit field count** (reasonable limits)
- [ ] **Return 422** for invalid fields

### Content-Type Validation
- [ ] **Require application/json** for POST requests
- [ ] **Return 400** for unsupported content types
- [ ] **Handle missing Content-Type** gracefully

## 📊 Response Headers Checklist

### Required Headers
- [ ] **Content-Type**: `application/json; charset=utf-8`
- [ ] **Cache-Control**: appropriate caching directives
- [ ] **X-Request-ID**: unique request identifier (optional)

### Performance Headers
- [ ] **Response time tracking** in headers (optional)
- [ ] **Cache status indication** (hit/miss) (optional)

## 🔄 Controller Structure Checklist

### Controller Action Pattern
- [ ] **Extract and validate parameters** first
- [ ] **Call service objects** for business logic
- [ ] **Handle service responses** appropriately
- [ ] **Return consistent JSON** responses
- [ ] **Keep controllers thin** (no business logic)

### Example Controller Structure
```ruby
class DataController < ApplicationController
  def index
    # 1. Extract parameters
    url = params[:url]
    fields = JSON.parse(params[:fields] || '{}')
    
    # 2. Validate inputs
    validate_inputs!(url, fields)
    
    # 3. Call service
    result = WebScraperService.call(url, fields)
    
    # 4. Return response
    render json: result[:data], status: :ok
  rescue ValidationError => e
    render json: { error: e.message, status: 422 }, status: :unprocessable_entity
  end
  
  private
  
  def validate_inputs!(url, fields)
    # Validation logic here
  end
end
```

## 🎯 Service Integration Checklist

### Service Object Pattern
- [ ] **Use service objects** for business logic
- [ ] **Return consistent hashes** from services
- [ ] **Include data and metadata** in service responses
- [ ] **Handle errors in services** and raise appropriate exceptions

### Service Response Format
```ruby
# Service should return:
{
  data: { title: "...", price: "..." },
  cached: true,
  timestamp: Time.current
}
```

## 📋 API Documentation Checklist

### Endpoint Documentation
- [ ] **Document all endpoints** with examples
- [ ] **Include request formats** for each endpoint
- [ ] **Show response formats** for success and errors
- [ ] **List all possible status codes**
- [ ] **Provide curl examples** for testing

### README API Section
- [ ] **API overview** and purpose
- [ ] **Authentication requirements** (if any)
- [ ] **Rate limiting information**
- [ ] **Example requests and responses**
- [ ] **Error handling explanation**

## ✅ Testing Integration Checklist

### Request Spec Coverage
- [ ] **Test successful requests** (200 responses)
- [ ] **Test all error cases** (400, 422, 429, 500)
- [ ] **Test both GET and POST** endpoints
- [ ] **Test parameter validation**
- [ ] **Test response format consistency**

### Example Test Cases
```ruby
describe 'GET /data' do
  it 'returns scraped data for valid request' do
    get '/data', params: { url: 'https://example.com', fields: '{"title":"h1"}' }
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to have_key('title')
  end
  
  it 'returns 400 for missing URL' do
    get '/data'
    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)['error']).to include('Missing')
  end
end
```

## 🚀 Performance Considerations

### Response Optimization
- [ ] **Return only requested fields**
- [ ] **Minimize response payload size**
- [ ] **Use appropriate HTTP caching**
- [ ] **Include cache status** in responses

### Request Handling
- [ ] **Process requests efficiently**
- [ ] **Implement request timeouts**
- [ ] **Handle concurrent requests** safely

---

## ✅ Pre-Deployment Checklist

### API Completeness
- [ ] All endpoints return proper JSON
- [ ] All error cases handled consistently
- [ ] Input validation working correctly
- [ ] Response format matches specification
- [ ] Status codes used appropriately

### Quality Assurance
- [ ] API tests cover all endpoints
- [ ] Error handling tested thoroughly
- [ ] Performance acceptable under load
- [ ] Documentation complete and accurate
- [ ] Ready for technical review

**Remember: Clean, consistent API design demonstrates professional Rails development skills!**