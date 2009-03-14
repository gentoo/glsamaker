require 'test_helper'

class PermissionTest < ActiveSupport::TestCase
  fixtures :permissions

  test "uniqueness" do
    p = Permission.new(:name => permissions(:file_draft).name,
                       :title => "This permission should already be there")

    assert !p.save
    assert p.errors.invalid?(:name)
  end
  
  test "empty required fields" do
    p = Permission.new(:name => '', :title => '')
    
    assert !p.save
    assert p.errors.invalid?(:name)
    assert p.errors.invalid?(:title)
  end
  
  test "successful creation" do
    p = Permission.new(:name => 'testperm', 
                       :title => 'Test permission', 
                       :description => 'This is a wonderful test permission.')

    assert(p.save, "Couldn't create permission")
  end
end
