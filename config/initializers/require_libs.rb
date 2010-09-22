<<<<<<< HEAD
unless Rails.env == 'development'
  require 'lib/authentication'
  require 'lib/diff'
  require 'lib/glsamaker'
  #require 'lib/glsamaker/diff'
  #require 'lib/glsamaker/portage'
  require 'lib/glsamaker/helpers'
  #require 'lib/glsamaker/xml'
  #require 'lib/glsamaker/http'
  #require 'lib/glsamaker/bugs'
  require 'lib/bugzilla'
  #require 'lib/bugzilla/bug'
  #require 'lib/bugzilla/history'
  #require 'lib/bugzilla/comment'
end

# vim: ts=2 sw=2 et ft=ruby sts=2 tw=72 nospell:

