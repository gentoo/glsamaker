# ===GLSAMaker v2
#  Copyright (C) 2009-11 Alex Legler <a3li@gentoo.org>
#  Copyright (C) 2006-07 Jean-Philippe Lang
#  Copyright (C) 2008 Robert Buchholz <rbu@gentoo.org> and Tobias Heinlein <keytoaster@gentoo.org>
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
    cves.uniq.each do |cve|
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
    summary = summary.gsub(/[ (]*CVE-(\d{4})([-,(){}|, \d]+)/, '')
    summary.gsub!(/\(?CVEs? requested\)?/, '')
    "#{summary} (#{cve_str})"
  end
  
  # Returns the appropriate severity setting for a given whiteboard string
  def whiteboard_to_severity(wb)
    return 'normal' if wb.length < 2

    ev = wb[0..1]
    case ev
    when 'A0', 'B0'
      'blocker'
    when 'A1', 'C0'
      'critical'
    when 'A2', 'B1', 'C1'
      'major'
    when 'A3', 'B2', 'C2'
      'normal'
    when 'A4', 'B3', 'B4', 'C3'
      'minor'
    when 'C4', '~0', '~1', '~2', '~3', '~4'
      'trivial'
    else
      'normal'
    end
  end

  # Simplistic helper for rendering an error message.
  # Shows a little icon before the message
  def error_msg(msg)
    content = image_tag('icons/error.png')
    content << " " << msg
    content
  end

  # Checks a string for spelling mistakes
  def spelling(str)
    Glsamaker::Spelling.check_string(str, '<span class="spelling-error">'.html_safe, '</span>'.html_safe)
  rescue
    Rails.logger.error "Spell checking not available"
    str
  end

  # Renders a title bar for our boxes
  def box_title(title, options = {})
    content = "".html_safe

    if options.has_key? :toolbar
      span_content = "".html_safe

      options[:toolbar].each do |toolbar_item|
        if toolbar_item == :sep
          span_content << image_tag('separator.png')
        else
          if toolbar_item[:uri].start_with? 'javascript:'
            span_content << link_to_function(
                image_tag(toolbar_item[:icon]),
                toolbar_item[:uri].gsub(/^javascript:/, ''),
                :title => toolbar_item[:title]
            ) << ' '
          else
            span_content << link_to(image_tag(toolbar_item[:icon]), toolbar_item[:uri]) << ' '
          end
        end
      end

      content << content_tag("span", span_content, :class => 'toolbar')
    end

    if options.has_key? :icon
      content << image_tag(options[:icon]) << " "
    end

    title2 = title
    if options.has_key? :escape and options[:escape] == false
      title2 = title2.html_safe
    end

    if options.has_key? :label
      content << content_tag('label', title2, :for => options[:label])
    else
      content << title2
    end

    content_tag("h2", content, :class => "boxtitle")
  end

  def with_format(format, &block)
    old_formats = formats
    begin
      self.formats = [format]
      return block.call
    ensure
      self.formats = old_formats
    end
  end
end
