# GLSAMaker v2
# Copyright (C) 2009 Alex Legler <a3li@gentoo.org>
# Copyright (C) 2009 Pierre-Yves Rofes <py@gentoo.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# For more information, see the LICENSE file.

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
      glsa.glsa_id = Digest::MD5.hexdigest(Time.now.to_s)
      glsa.status = "draft"
      
      begin
        glsa.save!
      rescue Exception => e
        flash[:error] = "Error while saving GLSA object #{e.message}"
        render :action => "new-request"
        return
      end

      revision = Revision.new
      revision.glsa = glsa
      revision.description = params[:description]
      
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
  end

  def edit
    @glsa = Glsa.find(params[:id])
    @rev = @glsa.revisions[@glsa.revisions.length - 1]
    @glsa.update_attributes(params[:glsa])
    @rev.update_attributes(params[:rev])
  end

  def update
    @glsa = Glsa.find(params[:id])
    @rev = @glsa.revisions[@glsa.revisions.length - 1]
    @glsa.update_attributes(params[:glsa])
    @rev.update_attributes(params[:rev])
    redirect_to :action => 'show', :id => @glsa
  end

  def destroy
  end

  def comment
  end

end
