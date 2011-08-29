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
    @last_revision ||= self.revisions.order("revid DESC").first
  end

  # Returns the last revision object that was a release
  def last_release_revision
    self.revisions.where(:is_release => true).order('release_revision DESC').first
  end
  
  # Invalidates the last revision cache
  def invalidate_last_revision_cache
    @last_revision = nil
  end

  # Returns the next revision ID to be given for this GLSA
  def next_revid
    if (rev = last_revision)
      rev.revid + 1
    else
      0
    end
  end

  # Returns the next release revision ID to be given for this GLSA
  def next_releaseid
    if (rev = last_release_revision)
      rev.release_revision + 1
    else
      1
    end
  end

  # Returns all approving comments
  def approvals
    comments.where(:rating => 'approval')
  end

  # Returns all rejecting comments
  def rejections
    comments.where(:rating => 'rejection')
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

    if comments.where(:rating => 'approval', :user_id => user.id).all.count > 1
      return :approved
    end

    if comments.where(:user_id => user.id).all.count > 1
      return :commented
    end

    return :todo
  end
  
  # Returns true if there are any pending comments left
  def has_pending_comments?
    comments.where(:read => false).all.count > 0
  end
  
  # Returns all CVEs linked to this GLSA
  def related_cves
    last_revision.bugs.map do |bug|
      CveAssignment.find_all_by_bug(bug.bug_id).map {|assignment| assignment.cve}.uniq
    end.flatten
  end
  
  # Bulk addition of references.
  # Expects an array of hashes <tt>{:title => ..., :url => ...}</tt>
  def add_references(refs)
    rev = last_revision.deep_copy
    
    refs.each do |reference|
      rev.references.create(reference)
    end
    
    invalidate_last_revision_cache
    self
  end
  
  # Performs the steps to release the GLSA, performing santiy checks.
  def release
    raise GLSAReleaseError, 'Cannot release the GLSA as it is not approved' if not is_approved?
    raise GLSAReleaseError, 'Cannot release the GLSA as there are comments pending' if has_pending_comments?
    # TODO: releasing someone else's draft
    release!
  end
  
  # Performs the steps to release the GLSA, performing not as many checks. The +release+ method is to be preferred.
  def release!
    # This one is not avoidable. Some information is only filled in during the first edit, thus making it required.
    raise GLSAReleaseError, 'Cannot release the GLSA as it is not in "draft" or "release" status' if not (self.status == 'draft' or self.status == 'release')

    rev = last_revision.deep_copy
    rev.is_release = true
    rev.release_revision = next_releaseid
    rev.save!

    unless self.status == 'release'
      self.glsa_id = Glsa.next_id
      self.first_released_at = Time.now
    end

    self.status = 'release'
    save!
  end

  # Calculates the next GLSA ID for the given month, or the current month
  def self.next_id(month = Time.now)
    month_id = month.strftime("%Y%m")
    items = Glsa.where("glsa_id LIKE ? AND status = ?", month_id + '%', 'release').order('glsa_id DESC')

    return "#{month_id}-01" if items.length == 0

    items.first.glsa_id =~ /^#{month_id}-(\d+)$/
    next_id = Integer($1) + 1
    "#{month_id}-#{format "%02d", next_id}"
  end

  # Files a new GLSA request
  def self.new_request(title, bugs, comment, access, import_references, user)
    glsa = Glsa.new
    glsa.requester = user
    glsa.glsa_id = Digest::MD5.hexdigest(title + Time.now.to_s)[0...9]
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

    bugs = Bugzilla::Bug.str2bugIDs(bugs)

    bugs.each do |bug|
      begin
        b = Glsamaker::Bugs::Bug.load_from_id(bug)
      
        revision.bugs.create(
          :bug_id => bug,
          :title => b.summary,
          :whiteboard => b.status_whiteboard,
          :arches => b.arch_cc.join(', ')
        )
      rescue Exception => e
        # In case of bugzilla errors, just keep the bug #
        revision.bugs.create(:bug_id => bug)
      end
    end

    if import_references
      logger.debug { "importing references" }
      refs = []
      glsa.related_cves.each do |cve|
        refs << {:title => cve.cve_id, :url => cve.url}
      end
      glsa.add_references refs
    end

    glsa
  end

end

class GLSAReleaseError < StandardError; end