require 'test_helper'

class AuthenticationTest < ActionDispatch::IntegrationTest
  fixtures :all

  test "successful login" do
    get '/', {}, { 'HTTP_AUTHORIZATION' => basic_auth_creds(users(:test_member).login, GLSAMAKER_DEVEL_PASSWORD) }
    assert_response :success
  end

  test "unknown user login" do
    get '/', {}, { 'HTTP_AUTHORIZATION' => basic_auth_creds("doesnotexist", "invalidpassword") }
    assert_response 401
  end

  test "locked user login" do
    get '/', {}, { 'HTTP_AUTHORIZATION' => basic_auth_creds(users(:test_locked).login, GLSAMAKER_DEVEL_PASSWORD) }
    assert_response 401
  end
end
