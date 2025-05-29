# frozen_string_literal: true

require "uri"
require "ipaddr"
require_relative "../../lib/scraper_errors"

# Service for validating URLs with SSRF protection
# Prevents Server-Side Request Forgery attacks by blocking private IPs and dangerous hosts
class UrlValidatorService
  # Maximum allowed URL length
  MAX_URL_LENGTH = 2048

  # Private IP address ranges to block (RFC 1918, RFC 3927, etc.)
  PRIVATE_IP_RANGES = [
    IPAddr.new("10.0.0.0/8"),        # Private Class A
    IPAddr.new("172.16.0.0/12"),     # Private Class B
    IPAddr.new("192.168.0.0/16"),    # Private Class C
    IPAddr.new("127.0.0.0/8"),       # Loopback
    IPAddr.new("169.254.0.0/16"),    # Link-local
    IPAddr.new("::1/128"),           # IPv6 loopback
    IPAddr.new("fc00::/7"),          # IPv6 unique local
    IPAddr.new("fe80::/10")          # IPv6 link-local
  ].freeze

  # Hostnames that should be blocked for security reasons
  BLOCKED_HOSTNAMES = %w[
    localhost
    127.0.0.1
    0.0.0.0
    metadata.google.internal
    169.254.169.254
  ].freeze

  # Allowed URL schemes
  ALLOWED_SCHEMES = %w[http https].freeze

  def self.call(url)
    new(url).call
  end

  def initialize(url)
    @url = url&.strip
  end

  def call
    validate_url_presence
    validate_url_format
    validate_url_length
    validate_scheme
    validate_host_security

    @parsed_uri
  end

  private

  def validate_url_presence
    raise ScraperErrors::ValidationError, "URL cannot be blank" if @url.nil? || @url.empty?
  end

  def validate_url_format
    @parsed_uri = URI.parse(@url)
  rescue URI::InvalidURIError => e
    raise ScraperErrors::ValidationError, "Invalid URL format: #{e.message}"
  end

  def validate_url_length
    return unless @url.length > MAX_URL_LENGTH

    raise ScraperErrors::ValidationError, "URL too long (max #{MAX_URL_LENGTH} characters)"
  end

  def validate_scheme
    return if ALLOWED_SCHEMES.include?(@parsed_uri.scheme)

    raise ScraperErrors::ValidationError, "URL scheme '#{@parsed_uri.scheme}' not allowed. Must be HTTP or HTTPS"
  end

  def validate_host_security
    host = @parsed_uri.host
    raise ScraperErrors::ValidationError, "URL must have a host" if host.nil? || host.empty?

    # Check for blocked hostnames (case-insensitive)
    if BLOCKED_HOSTNAMES.any? { |blocked| host.casecmp?(blocked) }
      raise ScraperErrors::SecurityError, "Access to host '#{host}' is not allowed"
    end

    # Check for private IP addresses
    validate_ip_address(host)
  end

  def validate_ip_address(host)
    # Try to parse as IP address
    ip_addr = IPAddr.new(host)

    # Check if it's in any private range
    if PRIVATE_IP_RANGES.any? { |range| range.include?(ip_addr) }
      raise ScraperErrors::SecurityError, "Access to private IP address '#{host}' is not allowed"
    end
  rescue IPAddr::InvalidAddressError
    # Not an IP address, which is fine for domain names
    nil
  end
end
