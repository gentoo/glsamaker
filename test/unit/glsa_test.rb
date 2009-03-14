require 'test_helper'

class GLSATest < ActiveSupport::TestCase
  fixtures :glsas, :users
  
  test "uniqueness" do
    glsa = Glsa.new(:glsa_id => glsas(:glsa_one).glsa_id)
    
    assert !glsa.save
    assert glsa.errors.invalid?(:glsa_id)
  end
  
  test "successful creation" do
    glsa = Glsa.new(:glsa_id => "GLSA-2004-99")
    
    glsa.submitter = users(:test_user)
    glsa.requester = users(:test_user)
    glsa.bugreadymaker = users(:test_user)
    
    assert glsa.save
  end
end
