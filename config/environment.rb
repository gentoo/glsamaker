# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Glsamaker::Application.initialize!

GLSAMAKER_VERSION="2.0"

require 'digest/md5'