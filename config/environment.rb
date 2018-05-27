# Load the rails Rpplication
require File.expand_path('../application', __FILE__)

# Initialize the Rails application
Rails.application.initialize!

GLSAMAKER_VERSION = '2.1.12'

require 'digest/md5'
