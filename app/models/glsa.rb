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

  belongs_to :submitter, :class_name => "User", :foreign_key => "submitter"
  belongs_to :requester, :class_name => "User", :foreign_key => "requester"
  belongs_to :bugreadymaker, :class_name => "User", :foreign_key => "bugreadymaker"

  has_many :revisions
  has_many :comments

  # Returns the last revision object, referring to the current state of things
  def last_revision
    @last_revision ||= self.revisions.find(:first, :order => "revid DESC")
  end
end
