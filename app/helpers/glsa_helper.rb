# ===GLSAMaker v2
#  Copyright (C) 2009 Alex Legler <a3li@gentoo.org>
#  Copyright (C) 2009 Pierre-Yves Rofes <py@gentoo.org>
#  Copyright (C) 2006-2007 Jean-Philippe Lang
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

# GLSA Helper
module GlsaHelper
  
  def glsa_content(g, field)
    (params[:glsa][field.to_sym] if params[:glsa]) || g[field]
  end
  
  def lastrev_content(g, field)
    (params[:glsa][field.to_sym] if params[:glsa]) || g.last_revision[field]
  end
  
  def html_diff(wdiff)
    words = wdiff.words.collect{ |word| h(word) }
    words_add = 0
    words_del = 0
    dels = 0
    del_off = 0
    wdiff.diff.diffs.each do |diff|
      add_at = nil
      add_to = nil
      del_at = nil
      deleted = ""	    
      diff.each do |change|
        pos = change[1]
        if change[0] == "+"
          add_at = pos + dels unless add_at
          add_to = pos + dels
          words_add += 1
        else
          del_at = pos unless del_at
          deleted << ' ' + change[2]
          words_del	 += 1
        end
      end
      if add_at
        words[add_at] = '<span class="diff_in">' + words[add_at]
        words[add_to] = words[add_to] + '</span>'
      end
      if del_at
        words.insert del_at - del_off + dels + words_add, '<span class="diff_out">' + deleted + '</span>'
        dels += 1
        del_off += words_del
        words_del = 0
      end
    end
    simple_format_without_paragraph(words.join(" "))
  end
  
  def add_vulnerable_package_link(name)
    link_to_function name, :title => "Add package" do |page|
      page.insert_html :bottom, :packages_table_vulnerable, :partial => 'package', :object => Package.new(:comp => "<", :arch => "*", :my_type => "vulnerable")
    end
  end

  def add_unaffected_package_link(name)
    link_to_function name, :title => "Add package" do |page|
      page.insert_html :bottom, :packages_table_unaffected, :partial => 'package', :object => Package.new(:comp => ">=", :arch => "*", :my_type => "unaffected")
    end
  end
  
  def add_reference_link(name)
    link_to_function name, :title => "Add reference" do |page|
      page.insert_html :bottom, :references_table, :partial => 'reference', :object => Reference.new
    end
  end
  
  def status_icon(status)
    if status == "request"
      image_tag "icons/request.png", :title => "This item is a request."
    elsif status == "draft"
      image_tag "icons/draft.png", :title => "This item is a draft."
    elsif status == "release"
      image_tag "icons/sent.png", :title => "This item is a sent GLSA."
    else
      "?"
    end
  end
  
  def bugready_icon(status)
    if status
      image_tag "icons/bug.png", :title => "This item is bug ready."
    else
      image_tag "icons/bug-grey.png", :title => "This item is a NOT bug ready."
    end
  end
  
  def approval_icon(status)
    if status == :approved
      image_tag "icons/status-green.png", :title => "This item is approved for sending."
    elsif status == :commented
      image_tag "icons/status-red.png", :title => "This item has received comments."
    elsif status == :comments_pending
      image_tag "icons/status-yellow.png", :title => "This item has received comments."
    else
      image_tag "icons/status-grey.png", :title => "This item has no comments."
    end
  end

  def workflow_icon(status)
    if status == :commented
      image_tag "icons/commented.png", :title => "You have commented on this item."
    elsif status == :approved
      image_tag "icons/approved.png", :title => "You have approved this item."
    elsif status == :own
      image_tag "icons/user.png", :title => "This is your own draft."
    elsif status == :todo
      image_tag "icons/not-approved.png", :title => "Please comment and/or approve."
    end
  end
  
  def restricted_icon(status)
    if status
      image_tag "icons/confidential.png", :title => "This item is CONFIDENTIAL."
    else
      image_tag "icons/public.png", :title => "This item is public."
    end
  end
end

