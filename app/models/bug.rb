class Bug < ActiveRecord::Base
  belongs_to :revision
  
  # Returns the Gentoo Bugzilla URI for the bug.
  # Set +secure+ to false to get a HTTP instead of a HTTPS URI
  def bug_url(secure = true)
    if secure
      "https://bugs.gentoo.org/show_bug.cgi?id=#{self.bug_id}"
    else
      "http://bugs.gentoo.org/show_bug.cgi?id=#{self.bug_id}"
    end
  end
end
