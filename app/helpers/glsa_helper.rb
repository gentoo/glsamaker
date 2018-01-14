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

# GLSA Helper
module GlsaHelper
  
  def glsa_content(g, field)
    (params[:glsa][field.to_sym] if params[:glsa]) || g[field]
  end
  
  def lastrev_content(g, field)
    (params[:glsa][field.to_sym] if params[:glsa]) || g.last_revision[field]
  end
  
  def add_vulnerable_package_link(name)
    link_to_function(
        name,
        "Element.insert('packages_table_vulnerable', { bottom: '#{escape_javascript(render(:partial => '/glsa/package', :object =>  Package.new(:comp => "<", :slot => "*", :arch => "*", :my_type => "vulnerable")))}' })",
        :title => 'Add package')
  end

  def add_unaffected_package_link(name)
    link_to_function(
        name,
        "Element.insert('packages_table_unaffected', { bottom: '#{escape_javascript(render(:partial => '/glsa/package', :object =>  Package.new(:comp => ">=", :slot => "*", :arch => "*", :my_type => "unaffected")))}' })",
        :title => 'Add package')
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
      image_tag "icons/bug-grey.png", :title => "This item is NOT bug ready."
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

  def check_icon(status)
    if status
      image_tag "icons/ok.png", :title => "All checks passed"
    else
      image_tag "icons/error.png", :title => "Error. Cannot continue."
    end
  end

  def is_approval_icon(status)
    if status
      image_tag 'icons/approval.png', :title => 'This item is an approval'
    else
      image_tag 'icons/rejection.png', :title => 'This item is a rejection'
    end
  end
  
  def prefixed_item(prefix, text)
    tf = Text::Format.new()
    tf.first_indent = tf.body_indent = prefix.length + 1
    
    str = tf.format(text)
    str[0, prefix.length] = prefix  
    str.chomp
  end
  
  def adv_wrap(text, shorten_args = false)
    text.gsub!(/\r?\n/, "\n")
    
    text.gsub!(/<\/?(b|i)>/, '')

    text.gsub!(/^\*\s+(.*)$/) do |s|
      '* ' + word_wrap($1, :line_width => 69).gsub("\n","\n  ")
    end

    text.gsub!(/(?:<ul>\s*(.*?)<\/ul>(?:\s*\n)?)/m) do |s|
      $1.gsub(/<li>(.*?)<\/li>\s*/) do |t|
        ('* ' + word_wrap($1, :line_width => 69)).gsub("\n", "\n  ") + "\n\n"
      end
    end

    # TODO: ordered lists? never used...
    
    text.gsub!(/(?:<ol>\s*(.*?)<\/ol>(?:\s*\n)?)/m) do |s|
      nom = 0
      $1.gsub(/<li>(.*?)<\/li>\s*/) do |t|
        ("#{nom += 1}. " + word_wrap($1, :line_with => 68)).gsub("\n", "\n   ") + "\n\n"
      end
    end

    text.gsub!(/(?:<code>\s*(.*?)<\/code>(?:\s*\n)?)/m) do |s|      
      ('  ' + word_wrap(shorten_args ? shorten_args($1) : $1, :line_width => 69)).gsub("\n", "\n  ") + "\n\n"
    end
    
    word_wrap(text.chomp, :line_width => 71)
  end

  def template_popups
    render :partial => 'template_popups', :locals => {:templates => @templates}
  end

  def xml_format(str)
    content = Kramdown::Document.new(str || "").to_xml

    content.gsub! "<p><code>", "<code>"
    content.gsub! "</code></p>", "</code>"
    content.gsub! "&lsquo;", "'"
    content.gsub! "&rsquo;", "'"
    content.gsub! "&ldquo;", '"'
    content.gsub! "&rdquo;", '"'

    content
  end

  def html_format(str)
    content = Kramdown::Document.new(str || "").to_xml

    content.gsub! "<p><code>", "<code>"
    content.gsub! "</code></p>", "</code>"

    content
  end

  def field_content(str)
    sanitize(html_format(spelling(str)), :tags => %w[p ul li code span])
  end

private
  def shorten_args(text)
    text.gsub!(/# (.*)/) do |s|
      r = $1
      r_fallback = r.dup

      logger.debug r.inspect
      logger.debug r.length
      
      r.gsub!(/ --verbose /m, " -v ")     if r.length > 67
      r.gsub!(/ --ask /m, " -a ")         if r.length > 67
      r.gsub!(/ --oneshot /m, " -1 ")     if r.length > 67
      r.gsub!(/ -a -1 -v /m, " -1av ")    if r.length > 67
      
      r = r_fallback.gsub(/ --verbose /, " --verbose \\\n  ") if r.length > 67
      
      "# " + r
    end
  end
end

