# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.6"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.0"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# SQLite for testing when PostgreSQL not available
gem "sqlite3", "~> 1.4", group: :test

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.0"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 5.0"

# Web scraping gems
gem "http", "~> 5.1" # HTTP client library
gem "nokogiri", "~> 1.15" # HTML/XML parsing

# Background job processing
gem "sidekiq", "~> 8.0" # Background jobs with Redis

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://github.com/rails/rails/tree/main/activemodel#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem "rack-cors"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]

  # Testing framework
  gem "factory_bot_rails"
  gem "faker"
  gem "rspec-rails", "~> 6.0"

  # Additional testing gems
  gem "shoulda-matchers", "~> 5.3" # Additional RSpec matchers
  gem "webmock", "~> 3.18" # HTTP request stubbing

  # Code coverage - temporarily disabled
  # gem "simplecov", "~> 0.22", require: false
  # gem "simplecov-lcov", "~> 0.8", require: false
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  # Code quality and linting
  gem "rubocop", "~> 1.50", require: false
  gem "rubocop-performance", "~> 1.17", require: false
  gem "rubocop-rails", "~> 2.19", require: false
  gem "rubocop-rspec", "~> 2.20", require: false
end
