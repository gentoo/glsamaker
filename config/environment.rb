# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Glsamaker::Application.initialize!

GLSAMAKER_VERSION="1.9-git"

require 'digest/md5'