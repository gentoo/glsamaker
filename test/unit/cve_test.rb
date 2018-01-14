require 'test_helper'

class CveTest < ActiveSupport::TestCase
  test "URL generation" do
    cve = cves(:cve_one)
    
    assert_equal('https://nvd.nist.gov/vuln/detail/CVE-2004-1776', cve.url)
    assert_equal('https://nvd.nist.gov/vuln/detail/CVE-2004-1776', cve.url(:nvd))
    assert_equal('https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2004-1776', cve.url(:mitre))
    assert_raise(ArgumentError) { cve.url(:invalid_site) }
  end
  
  test "to_s" do
    assert_equal(
      "CVE-2004-1776 (https://nvd.nist.gov/vuln/detail/CVE-2004-1776):\n  Cisco IOS 12.1(3) and 12.1(3)T allows remote attackers to read and modify\n  device configuration data via the cable-docsis read-write community string\n  used by the Data Over Cable Service Interface Specification (DOCSIS)\n  standard.",
      cves(:cve_one).to_s
    )
  end
  
  test "assigning" do
    cve = cves(:cve_two)
    user = users(:test_user)
    
    assert_nothing_raised(Exception) { 
      cve.assign(99999, user)
    }
    
    assert_equal("ASSIGNED", cve.state)
    assert_equal(user.id, cve.cve_changes.first.user_id)
    assert_equal(99999, cve.assignments.first.bug)
  end
  
  test "nfu" do
    cve = cves(:cve_two)
    user = users(:test_user)
    
    assert_nothing_raised(Exception) { 
      cve.nfu(user)
    }
    
    assert_equal("NFU", cve.state)
    assert_equal(user.id, cve.cve_changes.first.user_id)
  end
  
  test "invalid" do
    cve = cves(:cve_two)
    user = users(:test_user)
    
    assert_nothing_raised(Exception) { 
      cve.invalidate(user)
    }
    
    assert_equal("INVALID", cve.state)
    assert_equal(user.id, cve.cve_changes.first.user_id)
  end
  
  test "later" do
    cve = cves(:cve_two)
    user = users(:test_user)
    
    assert_nothing_raised(Exception) { 
      cve.later(user)
    }
    
    assert_equal("LATER", cve.state)
    assert_equal(user.id, cve.cve_changes.first.user_id)
  end
  
  test "mark as new" do
    cve = cves(:cve_two)
    user = users(:test_user)
    
    assert_nothing_raised(Exception) { 
      cve.mark_new(user)
    }
    
    assert_equal("NEW", cve.state)
    assert_equal(user.id, cve.cve_changes.first.user_id)    
  end
  
  test "add comment" do
    cve = cves(:cve_two)
    user = users(:test_user)
    
    assert_nothing_raised(Exception) { 
      cve.add_comment(user, "Comment Text")
    }
    
    assert_equal("Comment Text", cve.comments.first.comment)
    assert_equal(user.id, cve.comments.first.user_id)
  end
end
