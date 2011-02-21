require 'test_helper'

class CVETest < ActiveSupport::TestCase
  test "URL generation" do
    cve = cves(:cve_one)
    
    assert cve.url, 'http://nvd.nist.gov/nvd.cfm?cvename=CVE-2004-1776'
    assert cve.url(:nvd), 'http://nvd.nist.gov/nvd.cfm?cvename=CVE-2004-1776'
    assert cve.url(:mitre), 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2004-1776'
  end
end
