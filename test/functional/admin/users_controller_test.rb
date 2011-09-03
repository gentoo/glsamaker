require 'test_helper'

class Admin::UsersControllerTest < ActionController::TestCase
  test "should work for admins" do
    log_in_as :admin
    get :index
    assert_response :success
  end

  test "should not grant access to regular users" do
    log_in_as :user
    get :index
    assert_redirected_to :controller => '/index', :action => 'error', :type => 'access'
  end
end
