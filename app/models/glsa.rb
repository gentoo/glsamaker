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

  # Returns all approving comments
  def approvals
    comments.find(:all, :conditions => ['rating = ?', 'approval'])
  end

  # Returns all rejecting comments
  def rejections
    comments.find(:all, :conditions => ['rating = ?', 'rejection'])
  end

  # Returns true if the draft is ready for sending
  def is_approved?
    (approvals.count - rejections.count) >= 2
  end

  # Returns true if it has comments
  def has_comments?
    comments.count > 0
  end

  # The approval status of the GLSA, either :approved, :commented, or :none
  def approval_status
    if is_approved?
      return :approved
    elsif has_comments?
      if has_pending_comments?
        return :comments_pending
      else
        return :commented
      end
    end
      return :none
  end

  # Returns true if user is the owner of this GLSA.
  def is_owner?(user)
    luser = (status == "request" ? requester : submitter)
    luser == user
  end

  # Returns the workflow status of this GLSA for a given user.
  # Return values: :own (own draft), :approved (approval given), :commented (comment or rejection given)
  def workflow_status(user)
    if is_owner?(user)
      return :own
    end

    if comments.find(:all, :conditions => ['rating = ? AND user_id = ?', 'approval', user.id]).count > 1
      return :approved
    end

    if comments.find(:all, :conditions => ['user_id = ?', user.id]).count > 1
      return :commented
    end

    return :todo
  end

  # Returns true if there are any pending comments left
  def has_pending_comments?
    comments.find(:all, :conditions => ['`read` = ?', false]).count > 0
  end

  # Calculates the next GLSA ID for the given month, or the current month
  def self.next_id(month = Time.now)
    month_id = month.strftime("%Y%m")
    items = find(:all, :conditions => ['glsa_id LIKE ? AND status = ?', month_id + '%', 'release'], :order => 'glsa_id DESC')

    return "#{month_id}-01" if items.length == 0

    items.first.glsa_id =~ /^#{month_id}-(\d+)$/
    next_id = Integer($1) + 1
    "#{month_id}-#{format "%02d", next_id}"
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
