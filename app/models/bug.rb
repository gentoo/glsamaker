# ===GLSAMaker v2
#  Copyright (C) 2009 Alex Legler <a3li@gentoo.org>
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
  
  def cc
    self.arches
  end
  
  include Glsamaker::Bugs::StatusMixin
  include Glsamaker::Bugs::ArchesMixin
  
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
