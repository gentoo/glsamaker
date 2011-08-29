#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Glsamaker::Application.load_tasks

begin
  require 'ci/reporter/rake/test_unit'
rescue LoadError
end