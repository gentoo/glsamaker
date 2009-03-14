# GLSAMaker v2
# Copyright (C) 2009 Alex Legler <a3li@gentoo.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# For more information, see the LICENSE file.

class Glsa < ActiveRecord::Base
  validates_uniqueness_of :glsa_id, :message => "must be unique"
  validates_presence_of :glsa_id, :message => "GLSA ID needed"

  has_one :submitter, :class_name => "User", :foreign_key => "user_id"
  has_one :requester, :class_name => "User", :foreign_key => "user_id"
  has_one :bugreadymaker, :class_name => "User", :foreign_key => "user_id"
  
  has_many :revisions
end
