# Performance Optimization Rules - Dotidot Web Scraper Challenge

## 🗄️ Database Performance Checklist

### Query Optimization
- [ ] **Avoid N+1 queries** - use includes/preload for associations
- [ ] **Use database indexes** on commonly queried fields
- [ ] **Limit query results** - use pagination for large datasets
- [ ] **Use select** to fetch only needed columns
- [ ] **Optimize WHERE clauses** - put most selective conditions first

### Database Indexes for Web Scraper
- [ ] **Index on created_at** for time-based queries
- [ ] **Index on url_hash** for URL lookups
- [ ] **Index on status** for filtering cached results
- [ ] **Composite index** on [url_hash, created_at]
- [ ] **Unique index** on url_hash for cache keys

### Database Configuration Example
```ruby
# Migration for scrape results
class CreateScrapeResults < ActiveRecord::Migration[7.1]
  def change
    create_table :scrape_results do |t|
      t.string :url_hash, null: false
      t.json :fields_requested
      t.json :scraped_data
      t.string :status, default: 'pending'
      t.timestamps
    end
    
    # Performance indexes
    add_index :scrape_results, :url_hash, unique: true
    add_index :scrape_results, :status
    add_index :scrape_results, :created_at
    add_index :scrape_results, [:url_hash, :created_at]
  end
end
```

## ⚡ Redis Caching Checklist

### Cache Strategy Setup
- [ ] **Configure Redis** as Rails cache store
- [ ] **Use consistent cache keys** with namespace
- [ ] **Set appropriate TTL** (time to live) for cached data
- [ ] **Implement cache warming** for frequently accessed data
- [ ] **Monitor cache hit/miss rates**

### Redis Configuration
- [ ] **Set up Redis connection** in config/application.rb
- [ ] **Configure cache expiration** (1 hour for scraped content)
- [ ] **Use Redis namespace** to avoid key collisions
- [ ] **Set memory limits** and eviction policies
- [ ] **Enable Redis persistence** if needed

### Redis Setup Example
```ruby
# config/application.rb
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  namespace: 'web_scraper_cache',
  expires_in: 1.hour,
  race_condition_ttl: 10.seconds
}

# Cache service implementation
class PageCacheService
  CACHE_TTL = 1.hour
  
  def self.get_or_set(url)
    cache_key = "scraped_page:#{Digest::SHA256.hexdigest(url)}"
    
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      yield if block_given?
    end
  end
  
  def self.invalidate(url)
    cache_key = "scraped_page:#{Digest::SHA256.hexdigest(url)}"
    Rails.cache.delete(cache_key)
  end
end
```

## 🚀 Background Processing Checklist

### Sidekiq Configuration
- [ ] **Add sidekiq gem** to Gemfile
- [ ] **Configure Sidekiq** to use Redis
- [ ] **Set worker concurrency** (start with 5 workers)
- [ ] **Configure queues** with priorities
- [ ] **Set job retries** and error handling

### Background Job Implementation
- [ ] **Create scraping jobs** for long-running tasks
- [ ] **Implement job progress tracking**
- [ ] **Add exponential backoff** for retries
- [ ] **Monitor job performance** and failures
- [ ] **Use appropriate queue priorities**

### Sidekiq Setup Example
```ruby
# Gemfile
gem 'sidekiq', '~> 7.0'

# config/sidekiq.yml
:concurrency: 5
:timeout: 30
:max_retries: 3

:queues:
  - [critical, 4]
  - [scraping, 2] 
  - [default, 1]

# Background job for heavy scraping
class WebScrapingJob < ApplicationJob
  queue_as :scraping
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  
  def perform(url, fields, user_id = nil)
    result = WebScraperService.call(url, fields)
    
    # Cache the result
    PageCacheService.set(url, result[:data])
    
    # Notify user if needed
    ScrapingCompleteNotification.new(user_id, result).deliver if user_id
  end
end
```

## 📊 HTTP Client Performance Checklist

### Optimize HTTP Requests
- [ ] **Use HTTP.rb** for best performance (faster than HTTParty)
- [ ] **Set reasonable timeouts** (10-15 seconds)
- [ ] **Implement connection pooling**
- [ ] **Use persistent connections** when possible
- [ ] **Handle response streaming** for large pages

### HTTP Client Configuration
- [ ] **Configure connection limits** per domain
- [ ] **Set User-Agent** to avoid blocks
- [ ] **Handle compression** (gzip/deflate)
- [ ] **Implement retry logic** with exponential backoff
- [ ] **Monitor request performance**

### HTTP Client Example
```ruby
class OptimizedHttpClient
  HTTP_CLIENT = HTTP.persistent('https://example.com')
                   .timeout(connect: 5, read: 15)
                   .headers('User-Agent' => 'WebScraper/1.0')
  
  def self.fetch_with_retries(url, max_retries: 3)
    retries = 0
    
    begin
      response = HTTP_CLIENT.get(url)
      validate_response!(response)
      response.body.to_s
      
    rescue HTTP::Error, Timeout::Error => e
      retries += 1
      if retries <= max_retries
        sleep(2 ** retries) # Exponential backoff
        retry
      else
        raise ConnectionError, "Failed after #{max_retries} retries: #{e.message}"
      end
    end
  end
  
  private_class_method def self.validate_response!(response)
    raise HTTP::Error, "HTTP #{response.code}" unless response.status.success?
    raise ResponseTooLarge if response.body.size > 10.megabytes
  end
end
```

## 🎯 Application Performance Checklist

### Memory Optimization
- [ ] **Avoid large object creation** in hot paths
- [ ] **Use streaming** for large response processing
- [ ] **Implement garbage collection** monitoring
- [ ] **Optimize string operations** (use symbols when possible)
- [ ] **Monitor memory usage** in production

### CPU Optimization
- [ ] **Profile slow methods** using Ruby profiler
- [ ] **Optimize regular expressions** 
- [ ] **Use efficient algorithms** for data processing
- [ ] **Minimize object allocations** in loops
- [ ] **Cache expensive computations**

### Application Performance Example
```ruby
# ✅ GOOD - Memory efficient processing
class EfficientDataExtractor
  def self.extract_data(html, selectors)
    doc = Nokogiri::HTML(html)
    result = {}
    
    # Process selectors efficiently
    selectors.each do |key, selector|
      result[key] = extract_single_field(doc, selector)
    end
    
    result
  end
  
  private_class_method def self.extract_single_field(doc, selector)
    element = doc.at_css(selector)
    element&.text&.strip
  end
end

# ❌ BAD - Creates multiple Nokogiri documents
class IneffientDataExtractor
  def self.extract_data(html, selectors)
    result = {}
    selectors.each do |key, selector|
      doc = Nokogiri::HTML(html) # Wasteful!
      result[key] = doc.at_css(selector)&.text&.strip
    end
    result
  end
end
```

## 📈 Monitoring & Metrics Checklist

### Performance Monitoring Setup
- [ ] **Track response times** for all endpoints
- [ ] **Monitor cache hit rates** 
- [ ] **Track background job performance**
- [ ] **Monitor memory and CPU usage**
- [ ] **Set up performance alerts**

### Key Metrics to Track
- [ ] **Average response time** per endpoint
- [ ] **Cache hit/miss ratios**
- [ ] **Background job queue depth**
- [ ] **Error rates** and types
- [ ] **Database query performance**

### Performance Monitoring Example
```ruby
class PerformanceMonitor
  def self.track_request(request_name)
    start_time = Time.current
    memory_before = memory_usage
    
    result = yield
    
    duration = Time.current - start_time
    memory_after = memory_usage
    
    log_performance({
      request: request_name,
      duration_ms: (duration * 1000).round(2),
      memory_delta_mb: ((memory_after - memory_before) / 1024.0 / 1024.0).round(2),
      timestamp: start_time.iso8601
    })
    
    result
  end
  
  private_class_method def self.memory_usage
    `ps -o rss= -p #{Process.pid}`.to_i
  end
  
  private_class_method def self.log_performance(metrics)
    Rails.logger.info("PERFORMANCE: #{metrics.to_json}")
  end
end

# Usage in controller
class DataController < ApplicationController
  def index
    PerformanceMonitor.track_request('scrape_data') do
      # Your scraping logic here
    end
  end
end
```

## 🔄 Caching Strategy Implementation

### Multi-Level Caching
- [ ] **Application-level caching** (Redis)
- [ ] **Database query caching** (Rails query cache)
- [ ] **HTTP response caching** (conditional requests)
- [ ] **Fragment caching** for view components
- [ ] **Low-level caching** for expensive operations

### Cache Invalidation Strategy
- [ ] **Time-based expiration** (TTL)
- [ ] **Manual invalidation** when data changes
- [ ] **Cache warming** for popular content
- [ ] **Cache versioning** for schema changes
- [ ] **Graceful cache failures** (fallback to source)

### Cache Strategy Example
```ruby
class WebScraperService
  def self.call(url, fields)
    cache_key = generate_cache_key(url, fields)
    
    # Try cache first
    cached_result = Rails.cache.read(cache_key)
    return format_cached_response(cached_result) if cached_result
    
    # Scrape fresh data
    scraped_data = scrape_fresh_data(url, fields)
    
    # Cache the result
    Rails.cache.write(cache_key, scraped_data, expires_in: 1.hour)
    
    format_response(scraped_data, cached: false)
  end
  
  private_class_method def self.generate_cache_key(url, fields)
    content_hash = Digest::SHA256.hexdigest("#{url}:#{fields.to_json}")
    "scraper:#{content_hash}"
  end
  
  private_class_method def self.format_cached_response(data)
    {
      data: data,
      cached: true,
      timestamp: Time.current
    }
  end
end
```

## ⚙️ Production Optimization Checklist

### Asset Optimization
- [ ] **Precompile assets** in production
- [ ] **Use CDN** for static assets
- [ ] **Implement asset fingerprinting**
- [ ] **Compress assets** (gzip)
- [ ] **Optimize image sizes**

### Server Configuration
- [ ] **Configure Puma** with appropriate workers/threads
- [ ] **Set up load balancing** if needed
- [ ] **Configure database pool** size
- [ ] **Implement health checks**
- [ ] **Set up proper logging**

### Production Configuration Example
```ruby
# config/puma.rb
workers ENV.fetch("WEB_CONCURRENCY") { 2 }
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

# config/database.yml
production:
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
  checkout_timeout: 5
  
# config/environments/production.rb
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  pool_size: 5,
  pool_timeout: 5
}
```

## 🧪 Performance Testing Checklist

### Benchmarking Setup
- [ ] **Benchmark critical paths** before optimization
- [ ] **Use consistent test data** for comparisons  
- [ ] **Test under realistic load** conditions
- [ ] **Measure multiple metrics** (time, memory, throughput)
- [ ] **Document performance baselines**

### Load Testing
- [ ] **Test API endpoints** under concurrent load
- [ ] **Verify cache performance** with high traffic
- [ ] **Test background job processing** under load
- [ ] **Monitor resource usage** during tests
- [ ] **Test failure scenarios** (cache misses, timeouts)

---

## ✅ Performance Deployment Checklist

### Pre-Deployment Performance Check
- [ ] All caching mechanisms configured and tested
- [ ] Background processing working efficiently
- [ ] Database indexes in place and optimized
- [ ] HTTP client optimized for target websites
- [ ] Performance monitoring enabled

### Production Performance Validation
- [ ] Response times under acceptable thresholds
- [ ] Cache hit rates meeting targets (>80%)
- [ ] Background jobs processing within limits
- [ ] Memory and CPU usage stable
- [ ] Error rates minimal (<1%)

**Remember: Performance optimization is an ongoing process - measure, optimize, and monitor continuously!**