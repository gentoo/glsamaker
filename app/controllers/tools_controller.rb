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

# Tools controller
class ToolsController < ApplicationController
  layout false
  
  # Provides information for the 'file new request' page
  def file_req_ajax_info
    if params[:bugs] == nil
      render :text => "No bug given", :status => 500
      return
    end
    
    bug_ids = Bugzilla::Bug.str2bugIDs(params[:bugs])
    
    @bugs = []
    bug_ids.each do |bug_id|
      begin
        @bugs << Bugzilla::Bug.load_from_id(bug_id.to_i)
      rescue Exception => e
        @bugs << "Ignoring #{bug_id} #{e.message}"
      end
    end
    
    buginfo = render_to_string :template => 'tools/ajaxbugs', :layout => false
    
    # Generating a description
    @bugs.delete_if {|i| i.is_a? String}
    suggestion = nil
    
    if @bugs.length == 1
      @text = @bugs[0].summary
      suggestion = render_to_string :template => 'tools/ajaxdescr', :layout => false
    else
      @atoms = []
      @bugs.each do |bug|
        matchdata = /([\w-]+)\/([\w-]+)(-([\w.]+))?/.match(bug.summary)
        
        unless matchdata.nil?
          category = matchdata[1]
          package = matchdata[2].gsub(/-+?$/, '')
        
          @atoms << "#{category}/#{package}"
        end
      end
      
      @atoms.uniq!
      
      if @atoms.length > 0
        @text = @atoms.join(', ') + ": Multiple vulnerabilities"
        suggestion = render_to_string :template => 'tools/ajaxdescr', :layout => false
      end
    end
    
    suggestion ||= "(no suggestion available)"
    
    render :json => {"buginfo" => buginfo, "title" => suggestion}
  end
  
  def ajaxbugs
    bug_ids = Bugzilla::Bug.str2bugIDs(params[:bugs])
    
    @bugs = []
    bug_ids.each do |bug_id|
      begin
        @bugs << Bugzilla::Bug.load_from_id(bug_id.to_i)
      rescue Exception => e
        @bugs << "Ignoring #{CGI.escapeHTML(bug_id)} (#{CGI.escapeHTML(e.message)})"
      end
    end
    
    render :layout => false
  end
  
  def ajaxdescr
    bug_ids = Bugzilla::Bug.str2bugIDs(params[:bugs])
    
    @bugs = []
    bug_ids.each do |bug_id|
      begin
        @bugs << Bugzilla::Bug.load_from_id(bug_id.to_i)
      rescue Exception => e
      end
    end  
    
    if @bugs.length == 1
      @text = @bugs[0].summary
      render :layout => false
      return
    end
    
    # Process 2 or more bugs
    @atoms = []
    @bugs.each do |bug|
      matchdata = /([\w-]+)\/([\w-]+)(-([\w.]+))?/.match(bug.summary)
      
      unless matchdata.nil?
        category = matchdata[1]
        package = matchdata[2].gsub(/-+?$/, '')
        
        @atoms << "#{category}/#{package}"
      end
    end
    
    @atoms.uniq!
    
    if @atoms.length > 0
      @text = @atoms.join(', ') + ": Multiple vulnerabilities"
      render :layout => false
      return
    end

    render :text => "(no suggestion available)", :layout => false
  end

  def background
    render :layout => false
  end
end
