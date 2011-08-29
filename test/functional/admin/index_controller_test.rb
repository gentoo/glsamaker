require 'test_helper'

class Admin::IndexControllerTest < ActionController::TestCase
  test "should work for admins" do
    @request.env['HTTP_AUTHORIZATION'] = basic_auth_creds('admin', GLSAMAKER_DEVEL_PASSWORD)
    get :index
    assert_response :success
  end

  test "should not grant access to regular users" do
    @request.env['HTTP_AUTHORIZATION'] = basic_auth_creds('test', GLSAMAKER_DEVEL_PASSWORD)
    get :index
    assert_redirected_to :controller => '/index', :action => 'error', :type => 'access'
  end
end
