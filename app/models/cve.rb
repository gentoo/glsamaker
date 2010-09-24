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

class CVE < ActiveRecord::Base
  has_many :references, :class_name => "CVEReference"
  has_many :comments, :class_name => "CVEComment"
  has_and_belongs_to_many :cpes, :class_name => "CPE"
  has_many :cve_changes, :class_name => "CVEChange", :foreign_key => "cve_id"
  has_many :assignments, :class_name => "CVEAssignment", :foreign_key => "cve_id"
  
  def to_s(line_length = 78)
    str = "#{self.cve_id} #{"(http://nvd.nist.gov/nvd.cfm?cvename=%s):" % self.cve_id}\n"
    str += "  " + Glsamaker::help.word_wrap(self.summary, line_length-2).gsub(/\n/, "\n  ")
  end
  
  # Concatenates the CVE descriptions of many cves, separated by separator
  def self.concat(cves, separator = "\n\n")
    txt = ""
    cves.each do |cve|
      txt += CVE.find(cve).to_s
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
  
  # Looks for Gentoo packages that might be affected by this CVE
  def package_hints
    def search(s)
      Glsamaker::Portage.find_packages(
        Regexp.compile(Regexp.escape(s).gsub(/[^a-zA-Z0-9]/, '.*?'), Regexp::IGNORECASE)
      )
    end
    
    package_hints = []
    package_hints << cpes.map {|c| search c.product }.flatten
    
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
