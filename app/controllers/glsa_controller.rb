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

# GLSA controller
class GlsaController < ApplicationController
  before_filter :login_required

  def requests
    @glsas = Glsa.find(:all, :conditions => "status = 'request'", :order => "updated_at DESC")
  end

  def drafts
    @glsas = Glsa.find(:all, :conditions => "status = 'draft'", :order => "updated_at DESC")
  end

  def archive
    @glsas = Glsa.find(:all, :conditions => "status = 'release'", :order => "updated_at DESC")
  end
  
  def new
    @pageID = "new"
    @pageTitle = "New GLSA"
    
    if params[:what] == "request"
      render :action => "new-request"
    elsif params[:what] == "draft"
      render :action => "new-draft"
    else
      render
    end
  end

  def create
    if params[:what] == "request"
      begin
        glsa = Glsa.new_request(params[:title], params[:bugs], params[:comment], params[:access], current_user)
        flash[:notice] = "Successfully created GLSA #{glsa.glsa_id}"
        redirect_to :action => "requests"
      rescue Exception => e
        flash.now[:error] = e.message
        render :action => "new-request"
      end
    end
  end

  def show
    @glsa = Glsa.find(params[:id])
    @rev = params[:rev_id].nil? ? @glsa.last_revision : @glsa.revisions.find_by_revid(params[:rev_id])

    #flash.now[:error] = "[debug] id = %d, rev_id = %d" % [ params[:id], params[:rev_id] || -1 ]

    respond_to do |wants|
      wants.html { render }
      wants.xml { }
      wants.txt { render :text => "text to render..." }
    end

  end

  def edit
    @glsa = Glsa.find(params[:id])
    @rev = @glsa.last_revision
    
    # Reset added or removed bugs in the meantime
    session[:addbugs] ||= []
    session[:delbugs] ||= []
    session[:addbugs][@glsa.id] = []
    session[:delbugs][@glsa.id] = []
    
    # Packages
    @rev.vulnerable_packages.build(:comp => "<", :arch => "*") if @rev.vulnerable_packages.length == 0
    @rev.unaffected_packages.build(:comp => ">=", :arch => "*") if @rev.unaffected_packages.length == 0
    
    # References
    @rev.references.build if @rev.references.length == 0
    
    # Initialize for later use
    @comment_number = 1
  end

  def update
    @glsa = Glsa.find(params[:id])
    @rev = @glsa.last_revision
    
    if @glsa.nil?
      flash[:error] = "Unknown GLSA ID"
      redirect_to :action => "index"
      return
    end
    
    # GLSA object
    # The first editor is submitter
    # TODO: Maybe take a better condition (adding bugs would make so. the submitter)
    if @glsa.submitter.nil?
      @glsa.submitter = current_user
    end

    @glsa.status = "draft" if @glsa.status == "request"
    
    @glsa.restricted = (params[:glsa][:restricted] == "confidential")
    
    # Force update
    @glsa.updated_at = 0
    
    unless @glsa.save
      flash[:error] = "Errors occurred while saving the GLSA object"
      render :action => "edit"
    end
    
    revision = Revision.new
    revision.revid = @glsa.next_revid
    revision.glsa = @glsa
    revision.user = current_user    
    revision.title = params[:glsa][:title]
    revision.synopsis = params[:glsa][:synopsis]
    # TODO: secure
    revision.access = params[:glsa][:access]
    revision.severity = params[:glsa][:severity]
    revision.product = params[:glsa][:product]
    revision.description = params[:glsa][:description]
    revision.background = params[:glsa][:background]
    revision.impact = params[:glsa][:impact]
    revision.workaround = params[:glsa][:workaround]
    revision.resolution = params[:glsa][:resolution]
    
    unless revision.save
      flash.now[:error] = "Errors occurred while saving the Revision object"
      render :action => "edit"
      return
    end
    
    # Bugs...
    bugs = @rev.get_linked_bugs
    
    logger.debug { "Bugs: " + bugs.inspect }
    
    bugs += (session[:addbugs][@glsa.id] || [])
    
    logger.debug { "After adding new ones: " + bugs.inspect }
    
    bugs -= (session[:delbugs][@glsa.id] || [])
    
    logger.debug { "To remove: " + session[:delbugs][@glsa.id].inspect }
    logger.debug { "After removing: " + bugs.inspect }
    
    bugs.each do |bug|
      b = Bugzilla::Bug.load_from_id(bug)
      
      revision.bugs.create(
        :bug_id => bug,
        :title => b.summary
      )
    end
    logger.debug params[:glsa][:package].inspect
    
    # Packages...
    params[:glsa][:package].reject {|e| e.has_key? 'ignore'}.each do |package|
      logger.debug package.inspect
      revision.packages.create(package)
    end

    # References
    params[:glsa][:reference].reject {|e| e.has_key? 'ignore'}.each do |reference|
      logger.debug reference.inspect
      revision.references.create(reference)
    end

    flash[:notice] = "Saving was successful."
    redirect_to :action => 'show', :id => @glsa
    
  end
  
  def diff
    @glsa = Glsa.find(params[:id])
    
    if @glsa.nil?
      flash[:error] = "GLSA not found."
      redirect_to :action => "index"
      return
    end
    
    @rev_from = @glsa.revisions.find_by_revid(params[:from])
    @rev_to = @glsa.revisions.find_by_revid(params[:to])
    
    if @rev_from.nil? || @rev_to.nil? 
      flash[:error] = "Invalid revision given"
      redirect_to :action => "index"
      return
    end
    
    @diffs = {}
    @diff = Glsamaker::Diff::DiffContainer.new(@rev_from.description, @rev_to.description)
  end

  def addbug
    begin
      @glsa_id = Integer(params[:id])
    rescue Exception => e
      @glsa_id = nil
    end
    render :layout => false
  end
  
  def addbugsave
    @glsa = Glsa.find(params[:id].to_i)

    unless @glsa.nil?
      session[:addbugs][@glsa.id] ||= []
      @addedBugs = []
      Bugzilla::Bug.str2bugIDs(params[:addbugs]).map do |bugid|
        begin
          @addedBugs << Bugzilla::Bug.load_from_id(bugid)
          session[:addbugs][@glsa.id] << bugid.to_i
        rescue Exception => e
          # Silently ignore invalid bugs
        end
          
      end
      
      logger.debug session[:addbugs][@glsa.id].inspect
      
      begin
        render :layout => false
      rescue Exception => e
        render :text => "Error: #{e.message}", :status => 500
      end
    else
      render :text => "fail", :status => 500
    end
  end
  
  def delbug
    glsa = params[:id].to_i
    bug  = params[:bugid].to_i

    session[:addbugs][glsa] ||= []    
    session[:addbugs][glsa].delete(bug)

    session[:delbugs][glsa] ||= []
    session[:delbugs][glsa] << bug    
    
    render :text => ""
  end

  def destroy
  end

  def comment
  end

end
