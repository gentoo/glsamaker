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

# GLSA model
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
  
  # Returns the next revision ID to be given for this GLSA
  def next_revid
    if (rev = last_revision)
      rev.revid + 1
    else
      0
    end
  end
  
  # Files a new GLSA request
  def self.new_request(title, bugs, comment, access, user)
    glsa = Glsa.new
    glsa.requester = user
    glsa.glsa_id = Digest::MD5.hexdigest(title + Time.now.to_s)[0...10]
    glsa.restricted = (access == "confidential")
    glsa.status = "request"

    unless comment.strip.blank?
      glsa.comments << Comment.new(:rating => "neutral", :text => comment, :user => user)
    end
    
    begin
      glsa.save!
    rescue Exception => e
      raise Exception, "Error while saving the GLSA object: #{e.message}"
    end

    revision = Revision.new
    revision.revid = glsa.next_revid
    revision.glsa = glsa
    revision.title = title
    revision.user = user

    begin
      revision.save!
    rescue Exception => e
      glsa.delete
      raise Exception, "Error while saving Revision object: #{e.message}"
    end
    
    bug_ids = Bugzilla::Bug.str2bugIDs(bugs)

    bug_ids.each do |bug|
      begin
        bugzie = Bugzilla::Bug.load_from_id(bug)
      rescue Exception => e
        glsa.delete
        revision.delete
        raise Exception, "Error while loading bug id #{bug}: #{e.message}"
      end

      begin
        b = Bug.new
        b.revision = revision
        b.bug_id = bugzie.bug_id.to_i
        b.title = bugzie.summary
        b.save!
      rescue Exception => e
        glsa.delete
        revision.delete
        raise Exception, "Error while saving Bug object: #{e.message}"
      end
    end
  
    glsa
  end
  
end
