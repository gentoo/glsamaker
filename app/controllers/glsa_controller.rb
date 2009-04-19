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
  
  def index
    if params[:show] == "requests"
      @glsas = Glsa.find(:all)
    elsif params[:show] == "drafts"
      @glsas = Glsa.find(:all)
    elsif params[:show] == "sent"
      @glsas = Glsa.find(:all)
    else
      flash[:error] = "Don't know what to show you."
      redirect_to :controller => "index", :action => "index"
    end
  end
  
  def new
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
      bug_ids = Bugzilla::Bug.str2bugIDs(params[:bugs])
      
      glsa = Glsa.new
      glsa.requester = current_user
      glsa.glsa_id = Digest::MD5.hexdigest(params[:title] + Time.now.to_s)[0...10]
      glsa.restricted = params[:access] == "confidential"
      glsa.status = "request"
      
      begin
        glsa.save!
      rescue Exception => e
        flash[:error] = "Error while saving GLSA object #{e.message}"
        render :action => "new-request"
        return
      end

      revision = Revision.new
      revision.revid = glsa.next_revid
      revision.glsa = glsa
      revision.title = params[:title]
      revision.user = current_user
      
      begin
        revision.save!
      rescue Exception => e
        flash[:error] = "Error while saving Revision object"
        render :action => "new-request"
        return
      end
 
      bug_ids.each do |bug|
        begin
          bugzie = Bugzilla::Bug.load_from_id(bug)
        rescue Exception => e
        end

        begin
          b = Bug.new
          b.revision = revision
          b.bug_id = bugzie.bug_id.to_i
          b.title = bugzie.summary
          b.save!
        rescue Exception => e
          flash[:error] = "Error while saving Bug object"
          render :action => "new-request"
          return
        end
      end
    end

  end

  def show
    @glsa = Glsa.find(params[:id])
    @rev = @glsa.revisions.find(:first, :conditions => ['revid = ?', params[:rev_id]])

    flash[:error] = "[debug] id = %d, rev_id = %d" % [ params[:id], params[:rev_id] ]

    respond_to do |wants|
      wants.html { render }
      wants.xml { }
      wants.txt { render :text => "text to render..." }
    end

  end

  def edit
    @glsa = Glsa.find(params[:id])
    @rev = @glsa.last_revision
    
    # Reset added bugs in the meantime
    session[:addbugs] ||= []
    session[:addbugs][@glsa.id] = []

    render :action => "edit2"
  end

  def update
    @glsa = Glsa.find(params[:id])
    
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
    
    unless @glsa.save
      flash[:error] = "Errors occurred while saving the GLSA object"
      render :action => "edit2"
    end
    
    revision = Revision.new
    revision.revid = @glsa.next_revid
    revision.glsa = @glsa
    revision.user = current_user    
    revision.title = params[:glsa][:title]
    revision.synopsis = params[:glsa][:synopsis]
    # TODO: secure
    revision.access = params[:glsa][:access]
    revision.product = params[:glsa][:keyword]
    revision.description = params[:glsa][:description]
    revision.background = params[:glsa][:background]
    revision.impact = params[:glsa][:impact]
    revision.workaround = params[:glsa][:workaround]
    revision.resolution = params[:glsa][:resolution]
    
    unless revision.save
      flash[:error] = "Errors occurred while saving the GLSA object"
      render :action => "edit2"
    end
    
    # TODO: bugs, packages, references
    flash[:notice] = "Saving was successful."
    redirect_to :action => 'show', :id => @glsa
    
  end

  def destroy
  end

  def comment
  end

end
