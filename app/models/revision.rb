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

# Revision model
class Revision < ActiveRecord::Base
  belongs_to :glsa, :class_name => "Glsa", :foreign_key => "glsa_id"
  has_many :bugs
  has_many :references
  belongs_to :user
  
  validates_numericality_of :user_id, :message => "user id needed"
  validates_presence_of :title
  
  # Returns an Array of Integers of the bugs linked to this revision
  def get_linked_bugs
    self.bugs.map do |bug|
      bug.bug_id.to_i
    end
  end
  
  
end
