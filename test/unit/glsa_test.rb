require 'test_helper'

class GlsaTest < ActiveSupport::TestCase
  fixtures :glsas, :users
  
  test "uniqueness" do
    glsa = Glsa.new(:glsa_id => glsas(:glsa_one).glsa_id)
    
    assert !glsa.save
    assert glsa.invalid?(:glsa_id)
  end
  
  test "successful creation" do
    glsa = Glsa.new(:glsa_id => "GLSA-2004-99")
    
    glsa.submitter = users(:test_user)
    glsa.requester = users(:test_user)
    glsa.bugreadymaker = users(:test_user)
    
    assert glsa.save
  end
  
  test "new request" do
    glsa = Glsa.new_request(
      "Some title", 
      "236060, 260006",
      "some comment", 
      "public", 
      false,
      users(:test_user)
    )
    
    assert_equal(glsa.last_revision.title, "Some title")
    assert_equal(glsa.last_revision.bugs.map{|bug| bug.bug_id}.sort, [236060, 260006])
    assert !glsa.restricted
  end
  
  test "adding bulk references" do
    glsa = glsas(:glsa_two)

    glsa.add_references([
      {:title => "REF1", :url => "http://ref1/"},
      {:title => "REF2", :url => "http://ref2/"}
    ])
    
    assert glsa.valid?
    
    rev = glsa.last_revision
    assert rev.valid?
    assert_equal 'REF1', rev.references[0].title
    assert_equal 'http://ref1/', rev.references[0].url
    assert_equal 'REF2', rev.references[1].title
    assert_equal 'http://ref2/', rev.references[1].url
  end
end
