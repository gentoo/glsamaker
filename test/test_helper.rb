ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  set_fixture_class :cves => Cve

  fixtures :all

  # Add more helper methods to be used by all tests here...

  def basic_auth_creds(user, password)
    ActionController::HttpAuthentication::Basic.encode_credentials(user, password)
  end

  # Logs in as a user. Available users are
  # :user, :admin, :contributor, :padawan, :full_member, :confidential_member, :locked_user
  def log_in_as(who)
    user = nil
    case who
      when :user
        user = users(:test_user).login
      when :locked_user
        user = users(:test_locked).login
      when :admin
        user = users(:test_admin).login
      when :contributor
        user = users(:test_contributor).login
      when :padawan
        user = users(:test_padawan).login
      when :full_member
        user = users(:test_member).login
      when :confidential_member
        user = users(:test_confidential_member).login
    end

    raise "Invalid user" if user.nil?
    @request.env['HTTP_AUTHORIZATION'] = basic_auth_creds(user, GLSAMAKER_DEVEL_PASSWORD)
  end

  def assert_access_denied(message = nil)
    assert_redirected_to({:controller => '/index', :action => 'error', :type => 'access'}, message)
  end
end
