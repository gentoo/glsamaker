source 'https://rubygems.org'

gem 'rails', '~> 4.2'
gem 'xmlrpc'
gem 'rake', '10.4.2'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem 'mysql2', '~> 0.3.18'

gem 'json', '~>1.8.2'
gem 'jbuilder', '~> 2.0'

# Gems used only for assets and not required
# in production environments by default.
#group :assets do
#  gem 'sass-rails', "~> 3.2.0"
#  gem 'coffee-rails', "~> 3.2.0"
#  gem 'uglifier'
#end

gem 'prototype-rails', github: 'rails/prototype-rails', branch: '4.2'

# Use unicorn as the web server
#gem 'unicorn'
gem 'thin'

# Deploy with Capistrano
gem 'capistrano'

# gem 'exception_notification'

group :development do
#  No debugger at the moment because of the stupid build system of a dependency of ruby-debug19
#  gem 'ruby-debug', :platforms => :ruby_18
#  gem 'ruby-debug19', :platforms => :ruby_19
#  gem 'require_relative'
end

gem 'mechanize'
gem 'fastercsv'
gem 'diff-lcs', require: 'diff/lcs'
gem 'nokogiri'
gem 'text-format-revised', require: 'text/format'
gem 'kramdown'

gem 'thinking-sphinx', '~> 3.1.4'

#FIXME: runspell 0.0.1 is dead since 2011, we may need 
#to create a new spelling module

#gem 'runspell'

# gem "rdoc"

group :test do
  gem 'simplecov'
  gem 'ci_reporter'
  gem 'rspec'
  gem 'minitest-reporters'
end
