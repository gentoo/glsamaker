# ===GLSAMaker v2
#  Copyright (C) 2009-10 Alex Legler <a3li@gentoo.org>
#  Copyright (C) 2006-2007 Jean-Philippe Lang
#  Copyright (C) 2008 Robert Buchholz <rbug@gentoo.org> and Tobias Heinlein <keytoaster@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  # Same as Rails' simple_format helper without using paragraphs
  def simple_format_without_paragraph(text)
    text.to_s.
    gsub(/\r\n?/, "\n").                    # \r\n and \r -> \n
    gsub(/\n\n+/, "<br /><br />").          # 2+ newline  -> 2 br
    gsub(/([^\n]\n)(?=[^\n])/, '\1<br />')  # 1 newline   -> br
  end

  # shamelessly stolen from the old cvetools.py
  # Extracts all CVEs from a string into an array
  def get_bug_cves(str)
    cve_group_all = /[ (]*CVE-(\d{4})([-,(){}|, \d]+)/
    cve_group_split = /(\d{4})(?:\D|$)/

    bug_cves = []

    str.scan(cve_group_all).each do |m|
      m[1].scan(cve_group_split).each do |n|
        bug_cves << "CVE-%s-%s" % [m[0], n[0]]
      end
    end

    bug_cves
  end

  # Groups an array of CVE names into groups
  def bugs_unify_cvenames(cves)
    cve_r = /CVE-(\d{4})-(\d+)/

    years = {}
    cves.each do |cve|
      cve_r =~ cve
      years[$1] ||= []
      years[$1] << $2
    end

    title = ""
    years.keys.sort.each do |year|
      title += "CVE-%s" % year
      if years[year].size == 1
        title += "-%s," % years[year].first
      else
        title += "-{%s}," % years[year].sort.join(',')
      end
    end
    
    title[0, title.length - 1]
  end
  
  # Updates a bug string with the cve_ids
  def cveify_bug_title(summary, cve_ids)
    cve_str = bugs_unify_cvenames(get_bug_cves(summary) + cve_ids)
    summary = summary.gsub(/\(?CVEs?\s?(?:requested)?\)?/, "(#{cve_str})")
    summary = "#{summary} (#{cve_str})" unless summary.include?('CVE')
    summary
  end
  
end

