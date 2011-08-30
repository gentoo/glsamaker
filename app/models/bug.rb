# ===GLSAMaker v2
#  Copyright (C) 2009-2011 Alex Legler <a3li@gentoo.org>
#  Copyright (C) 2009 Pierre-Yves Rofes <py@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

# Bug model
class Bug < ActiveRecord::Base
  belongs_to :revision
  
  define_index do
    indexes title
    
    has revision_id
  end
  
  def cc
    self.arches
  end
  
  include Glsamaker::Bugs::StatusMixin
  include Glsamaker::Bugs::ArchesMixin
  include Glsamaker::Bugs::BugReadyMixin
  
  # Returns the Gentoo Bugzilla URI for the bug.
  # Set +secure+ to false to get a HTTP instead of a HTTPS URI
  def bug_url(secure = true)
    if secure
      "https://#{GLSAMAKER_BUGZIE_HOST}/show_bug.cgi?id=#{self.bug_id}"
    else
      "http://#{GLSAMAKER_BUGZIE_HOST}/show_bug.cgi?id=#{self.bug_id}"
    end
  end
  
  # Updates the cached bug metadata
  def update_cached_metadata
    b = Glsamaker::Bugs::Bug.load_from_id(bug_id)
  
    update_attributes!(
      :title => b.summary,
      :whiteboard => b.status_whiteboard,
      :arches => b.arch_cc.join(', ')
    )
  rescue Exception => e
    raise "Could not update cached metadata: " + e.message
  end
end
