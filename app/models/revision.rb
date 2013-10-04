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

require 'rexml/document'

# Revision model
class Revision < ActiveRecord::Base
  belongs_to :glsa, :class_name => "Glsa", :foreign_key => "glsa_id"
  has_many :bugs, :dependent => :destroy
  has_many :references, :dependent => :destroy
  has_many :packages, :dependent => :destroy
  has_many :vulnerable_packages, -> { where :my_type => "vulnerable" }, :class_name => "Package"
  has_many :unaffected_packages, -> { where :my_type => "unaffected" }, :class_name => "Package"
  belongs_to :user
  
  validates_numericality_of :user_id, :message => "user id needed"
  validates_presence_of :title

=begin
  validates_each :description, :resolution do |record, attr, value|
    # XML well-formedness test
    begin
      REXML::Document.new("<?xml version='1.0'?><root>#{value}</root>")
    rescue REXML::ParseException => e
      record.errors.add attr, "is not well-formed XML"
    end
  end
=end

  define_index do
    indexes title
    indexes synopsis
    indexes description
    indexes impact
    indexes workaround
    indexes resolution
    indexes is_release
    
    has glsa_id, revid, release_revision
  end
  
  # Returns an Array of Integers of the bugs linked to this revision
  def get_linked_bugs
    self.bugs.map do |bug|
      bug.bug_id.to_i
    end
  end
  
  # Checks all assigned bugs for bug ready status
  def bug_ready?
    self.bugs.each do |b|
      return false unless b.bug_ready?
    end
    
    return true
  end
  
  # Updates the cached metadata of all assigned bugs
  def update_cached_bug_metadata
    self.bugs.each do |b|
      b.update_cached_metadata
    end
  end
  
  # Creates a deep copy of a previous revision, copying all bugs, references and packages,
  # incrementing the revision ID by one.
  # <b>The caller must take care of deleting this revision again in case any error occurs later.</b>
  def deep_copy
    new_rev = dup
    new_rev.revid = glsa.next_revid
    
    references.each {|reference| new_rev.references << reference.dup }
    packages.each {|package| new_rev.packages << package.dup }
    bugs.each {|bug| new_rev.bugs << bug.dup }
    
    new_rev.save!
    new_rev
  end
  
  # Returns the packages linked to this revision grouped by atoms
  def packages_by_atom
    packages_list = {}
    self.packages.each do |p|
      packages_list[p[:atom]] ||= {}
      (packages_list[p[:atom]][p[:my_type]] ||= []) << p
    end
    
    packages_list
  end

  def to_s
    s = "r#{self.revid}"
    if self.is_release?
      s << " (release #{self.release_revision})"
    end

    s
  end

  def release_access
    if self.access == "both"
      "local, remote"
    else
      self.access
    end
  end
end
