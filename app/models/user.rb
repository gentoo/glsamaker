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

# =Access levels
#
# [<b>0 (Contributor)</b>] Can see own drafts, can fill in requests
# [<b>1 (Padawan)</b>] all of the above, plus see and edit all drafts
# [<b>2 (Full member)</b>] all of the above, plus voting
# [<b>3 (Confidential member)</b>] all of the above, including restricted drafts
class User < ActiveRecord::Base
  has_many :submitted_glsas, :class_name => "Glsa", :foreign_key => "submitter"
  has_many :requested_glsas, :class_name => "Glsa", :foreign_key => "requester"
  has_many :bugreadymade_glsas, :class_name => "Glsa", :foreign_key => "bugreadymaker"
  has_many :cve_changes, :class_name => "CVEChange", :foreign_key => "user_id"
  
  has_many :revisions

  validates_uniqueness_of :login, :message => "User name must be unique"
  validates_presence_of :login, :message => "User name can't be blank"
  
  validates_presence_of :name, :message => "Name can't be blank"

  validates_presence_of :access, :message => "Access level needed"
  validates_numericality_of :access, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 3, :message => "Access level must be between 0 and 3"
  
  validates_format_of :email, :with => /[\w.%+-]+?@[\w.-]+?\.\w{2,6}$/, :message => "Invalid Email address format"
  
  # Is the user an admin? ;)
  def is_el_jefe?
    self.jefe
  end
  
  # Checks access to a given GLSA
  def can_access?(glsa)
    return false if access == 0 and not glsa.is_owner? self
    return false if access < 3 and glsa.restricted
    
    true
  end
end
