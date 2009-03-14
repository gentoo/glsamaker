require 'test_helper'

class PermissionsUsersTest < ActiveSupport::TestCase
  fixtures :users, :permissions, :permissions_users
  
  test "set valid permission" do
    assert_nothing_raised(ArgumentError) {
      users(:test_user).grant_permission_for('file_glsa_draft')
    }
  end
  
  test "set invalid permission" do
    assert_raise(ArgumentError, "Permission not found") {  
      users(:test_user).grant_permission_for('invalid_perm')
    }
  end
  
  test "lookup if valid permission set" do
    assert_nothing_raised(ArgumentError) { 
      assert users(:test_user).has_permission_for?('file_glsa_draft')
      assert !users(:test_user).has_permission_for?('add_comment')      
    }
    
  end
  
  test "look up if invalid permission set" do
    assert_raise(ArgumentError, "Permission not found") {
      users(:test_user).has_permission_for?('not_existing')
    }
  end
  
  test "revoke valid permission" do
    assert_nothing_raised(ArgumentError) { 
      assert users(:test_user).revoke_permission_for('file_glsa_draft')
    }
  end
  
  test "revoke invalid permission" do
    assert_raise(ArgumentError, "Permission not found") {
      users(:test_user).revoke_permission_for('not_existing')
    }
  end
end
