#!/usr/bin/env ruby
# Manual test script for rate limiting functionality

puts "🔒 Testing Rate Limiting Implementation"
puts "=" * 50

# Test requires Rails environment
require_relative '../../config/environment'

puts "\n1. Rate Limiting Configuration Check:"
puts "   Rack::Attack enabled: #{defined?(Rack::Attack) ? '✅' : '❌'}"
puts "   Redis cache configured: #{Rails.cache.class.name.include?('Redis') ? '✅' : '❌'}"

puts "\n2. Rate Limiting Rules Configured:"
# Check if our throttling rules are loaded
throttles = Rack::Attack.instance_variable_get(:@throttles) || {}
puts "   IP throttling: #{throttles.key?('requests by ip') ? '✅' : '❌'}"
puts "   Domain throttling: #{throttles.key?('requests by domain') ? '✅' : '❌'}"
puts "   Global throttling: #{throttles.key?('requests globally') ? '✅' : '❌'}"

blocklists = Rack::Attack.instance_variable_get(:@blocklists) || {}
puts "   Security blocking: #{blocklists.key?('block malicious urls') ? '✅' : '❌'}"

puts "\n3. Redis Connection Test:"
begin
  Rack::Attack.cache.store.redis.ping
  puts "   Redis connection: ✅ Connected"
rescue => e
  puts "   Redis connection: ❌ Failed - #{e.message}"
end

puts "\n4. Cache Store Test:"
begin
  test_key = "rate_limit_test_#{Time.current.to_i}"
  Rack::Attack.cache.store.write(test_key, "test_value", expires_in: 10.seconds)
  value = Rack::Attack.cache.store.read(test_key)
  if value == "test_value"
    puts "   Cache operations: ✅ Working"
    Rack::Attack.cache.store.delete(test_key)
  else
    puts "   Cache operations: ❌ Failed"
  end
rescue => e
  puts "   Cache operations: ❌ Error - #{e.message}"
end

puts "\n5. Manual Testing Instructions:"
puts "   To test rate limiting manually:"
puts "   1. Start Rails server: rails server"
puts "   2. Make rapid requests to: http://localhost:3000/api/v1/data"
puts "   3. Use curl or similar tool:"
puts "      curl -X POST http://localhost:3000/api/v1/data \\"
puts "           -H 'Content-Type: application/json' \\"
puts "           -d '{\"url\":\"https://example.com\",\"fields\":{\"title\":\"h1\"}}'"
puts "   4. After 20 requests, should receive 429 status"

puts "\n6. Expected Rate Limit Response:"
puts "   Status: 429 Too Many Requests"
puts "   Headers: X-RateLimit-Limit, X-RateLimit-Remaining, Retry-After"
puts "   Body: JSON with success:false, error message, retry_after"

puts "\n✅ Rate Limiting Configuration Check Complete"
