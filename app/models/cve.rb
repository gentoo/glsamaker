# ===GLSAMaker v2
#  Copyright (C) 2010 Alex Legler <a3li@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

require 'glsamaker/helpers'

class Cve < ActiveRecord::Base
  has_many :references, :class_name => "CveReference"
  has_many :comments, :class_name => "CveComment"
  has_and_belongs_to_many :cpes, :class_name => "Cpe"
  has_many :cve_changes, :class_name => "CveChange", :foreign_key => "cve_id"
  has_many :assignments, :class_name => "CveAssignment", :foreign_key => "cve_id"
  
  def to_s(line_length = 78)
    str = "#{self.cve_id} #{"(%s):" % url}\n"
    str += "  " + Glsamaker::help.word_wrap(self.summary, line_length-2).gsub(/\n/, "\n  ")
  end
  
  # Returns the URL for this CVE at NVD (<tt>:nvd</tt>, default) or MITRE (<tt>:mitre</tt>)
  def url(site = :nvd)
    if site == :nvd
      "http://nvd.nist.gov/nvd.cfm?cvename=%s" % self.cve_id
    elsif site == :mitre
      "http://cve.mitre.org/cgi-bin/cvename.cgi?name=%s" % self.cve_id
    else
      raise ArgumentError, 'Invalid site'
    end
  end
  
  # Concatenates the CVE descriptions of many cves, separated by separator
  def self.concat(cves, separator = "\n\n")
    txt = ""
    cves.each do |cve|
      txt += Cve.find(cve).to_s
      txt += separator
    end
    txt
  end
  
  # Assigns the CVE to a certain bug, creating a history entry
  def assign(bugnr, user, action = 'assign')
    bugnr = Integer(bugnr)
    
    case action
    when 'assign', :assign
      act = 'assign'
    when 'file', :file
      act = 'file'
    else
      raise ArgumentError, "Invalid action specified"
    end
    
    a = self.assignments.create!(:bug => bugnr)
    
    ch = self.cve_changes.create!(
      :user => user,
      :action => act,
      :object => a.id
    )
    
    self.state = 'ASSIGNED'
    save!
  end
  
  # Mark the CVE as Not-For-Us, creating a history entry
  def nfu(user, reason = nil)
    self.cve_changes.create!(
      :user => user,
      :action => 'nfu',
      :object => reason
    )
    
    self.state = 'NFU'
    save!
  end
  
  # Mark the CVE as INVALID, creating a history entry
  def invalidate(user, reason = nil)
    self.cve_changes.create!(
      :user => user,
      :action => 'invalid',
      :object => reason
    )
    
    self.state = 'INVALID'
    save!
  end
  
  def later(user, reason = nil)
    self.cve_changes.create!(
      :user => user,
      :action => 'later',
      :object => reason
    )
    
    self.state = 'LATER'
    save!
  end
  
  def mark_new(user, reason = nil)
    self.cve_changes.create!(
      :user => user,
      :action => 'new',
      :object => reason
    )
    
    self.state = 'NEW'
    save!
  end
  
  def add_comment(user, comment, confidential = false)
    self.comments << CveComment.create!(
      :user => user,
      :confidential => confidential,
      :comment => comment
    )
  end
  
  # Decorates the output of field with a color, depending on the status
  def colorize(field = :cve_id)
    "<span class='cvename cve-%s'>%s</span>" % [state.downcase, self[field]]
  end
  
  # Looks for Gentoo packages that might be affected by this CVE
  def package_hints
    def search(s)
      return [] if s.nil? or s == ""
      
      Glsamaker::Portage.find_packages(
        Regexp.compile(Regexp.escape(s).gsub(/[^a-zA-Z0-9]/, '.*?'), Regexp::IGNORECASE)
      )
    end
    
    package_hints = []
    my_cpes = cpes.map {|c| c.product }.uniq
    package_hints << my_cpes.map {|c| search c }.flatten
    
    # stolen from the old cvetools.py
    if summary =~ / in (\S+\.\S+) in (?:the )?(?:a )?(\D+) \d+/
      match = $2
      if match.end_with? 'before'
        package_hints << search(match[0, match.length - 7])
      else
        package_hints << search(match)
      end
    end
    
    if summary =~ / in (?:the )?(?:a )?(\D+) \d+/
      match = $1
      if match.end_with? 'before'
        package_hints << search(match[0, match.length - 7])
      else
        package_hints << search(match)
      end
    end
    
    if summary =~ / in (\S+\.\S+) in (?:the )?(?:a )?(\S+) /
      package_hints << search($1)
    end
    
    if summary =~ / in (?:the )?(?:a )?(\S+) /
      package_hints << search($1)
    end
    
    if summary =~ /(?:The )?(\S+) /
      package_hints << search($1)
    end
    
    package_hints.flatten.uniq
  end
end