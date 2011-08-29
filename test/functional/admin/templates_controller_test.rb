require 'test_helper'

class Admin::TemplatesControllerTest < ActionController::TestCase
  setup do
    @template = templates(:one)
    @request.env['HTTP_AUTHORIZATION'] = basic_auth_creds('admin', GLSAMAKER_DEVEL_PASSWORD)
  end

  test "should not grant access to regular users" do
    @request.env['HTTP_AUTHORIZATION'] = basic_auth_creds('test', GLSAMAKER_DEVEL_PASSWORD)
    get :index
    assert_redirected_to :controller => '/index', :action => 'error', :type => 'access'
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:templates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create admin_template" do
    assert_difference('Template.count') do
      post :create, :admin_template => @template.attributes
    end

    assert_redirected_to admin_template_path(assigns(:template))
  end

  test "should show admin_template" do
    get :show, :id => @template.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @template.to_param
    assert_response :success
  end

  test "should update admin_template" do
    put :update, :id => @template.to_param, :template => @template.attributes
    assert_redirected_to admin_template_path(assigns(:template))
  end

  test "should destroy admin_template" do
    assert_difference('Template.count', -1) do
      delete :destroy, :id => @template.to_param
    end

    assert_redirected_to admin_templates_path
  end
end
