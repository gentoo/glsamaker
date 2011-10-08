# ===GLSAMaker v2
#  Copyright (C) 2010-11 Alex Legler <a3li@gentoo.org>
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
  def requests
    @pageID = "requests"
    @pageTitle = "Pooled GLSA requests"
    @glsas = Glsa.where(:status => 'request').order('updated_at DESC')
  end

  def drafts
    @pageID = "drafts"
    @pageTitle = "Pooled GLSA drafts"
    @glsas = Glsa.where(:status => 'draft').order('updated_at DESC')
  end

  def archive
    @pageID = "archive"
    @pageTitle = "GLSA archive"    

    respond_to do |format|
      format.html {
        @month = (params[:month] || Date.today.month).to_i
        @year = (params[:year] || Date.today.year).to_i

        month_start = Date.new(@year, @month, 1)
        month_end = Date.new(@year, @month + 1, 1) - 1

        @glsas = Glsa.where(:status => 'release', :first_released_at => month_start..month_end).order('updated_at DESC')
      }
      format.js {
        @month = params[:view]['month(2i)'].to_i
        @year = params[:view]['month(1i)'].to_i

        month_start = Date.new(@year, @month, 1)
        month_end = nil
        
        if @month == 12
          month_end = Date.new(@year + 1, 1, 1) -1
        else
          month_end = Date.new(@year, @month + 1, 1) - 1
        end

        @glsas = Glsa.where(:status => 'release', :first_released_at => month_start..month_end).order('updated_at DESC')
        @table = render_to_string :partial => "glsa_row", :collection => @glsas, :as => :glsa, :locals => { :view => :drafts }
      }
    end
  end
  
  def new
    @pageID = "new"
    @pageTitle = "New GLSA"
    
    # TODO: Straight-to-draft editing
    render :action => "new-request"
    return
    
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
        glsa = Glsa.new_request(params[:title], params[:bugs], params[:comment], params[:access], (params[:import_references].to_i == 1), current_user)
        
        Glsamaker::Mail.request_notification(glsa, current_user)
        
        flash[:notice] = "Successfully created GLSA #{glsa.glsa_id}"
        redirect_to :action => "requests"
      rescue Exception => e
        log_error e
        flash.now[:error] = e.message
        render :action => "new-request"
      end
    end
  end

  def show
    @glsa = Glsa.find(params[:id])
    return unless check_object_access!(@glsa)
    @rev = params[:rev_id].nil? ? @glsa.last_revision : @glsa.revisions.find_by_revid(params[:rev_id])

    if @rev == nil
      flash[:error] = "Invalid revision ID"
      redirect_to :action => "show"
      return
    end

    respond_to do |wants|
      wants.html { render }
      wants.xml { }
      wants.txt { render }
    end
  end

  def download
    @glsa = Glsa.find(params[:id])
    return unless check_object_access!(@glsa)
    @rev = params[:rev_id].nil? ? @glsa.last_revision : @glsa.revisions.find_by_revid(params[:rev_id])

    if @rev == nil
      flash[:error] = "Invalid revision ID"
      redirect_to :action => "show"
      return
    end

    text = nil
    respond_to do |wants|
      wants.xml { text = render_to_string(:action => :show, :format => 'xml')}
      wants.txt { text = render_to_string(:action => :show, :format => 'txt')}
      wants.html { render :text => "Cannot download HTML format. Pick .xml or .txt"; return }
    end
    
    send_data(text, :filename => "glsa-#{@glsa.glsa_id}.#{params[:format]}")
  end

  def edit
    @glsa = Glsa.find(params[:id])
    return unless check_object_access!(@glsa)
    @rev = @glsa.last_revision
    
    # Packages
    @rev.vulnerable_packages.build(:comp => "<", :arch => "*") if @rev.vulnerable_packages.length == 0
    @rev.unaffected_packages.build(:comp => ">=", :arch => "*") if @rev.unaffected_packages.length == 0
    
    # References
    @rev.references.build if @rev.references.length == 0

    @templates = {}
    GLSAMAKER_TEMPLATE_TARGETS.each do |target|
      @templates[target] = Template.where(:target => target).all
    end
  end

  def update
    @glsa = Glsa.find(params[:id])
    return unless check_object_access!(@glsa)
    @prev_latest_rev = @glsa.last_revision

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

    revision = Revision.new
    revision.revid = @glsa.next_revid
    revision.glsa = @glsa
    revision.user = current_user
    revision.title = params[:glsa][:title]
    revision.synopsis = params[:glsa][:synopsis]
    revision.access = params[:glsa][:access]
    revision.severity = params[:glsa][:severity]
    revision.product = params[:glsa][:product]
    revision.description = params[:glsa][:description]
    revision.background = params[:glsa][:background]
    revision.impact = params[:glsa][:impact]
    revision.workaround = params[:glsa][:workaround]
    revision.resolution = params[:glsa][:resolution]

    unless revision.save
      flash.now[:error] = "Errors occurred while saving the Revision object: #{revision.errors.full_messages.join ', '}"
      render :action => "edit"
      return
    end

    unless @glsa.save
      flash[:error] = "Errors occurred while saving the GLSA object"
      render :action => "edit"
    end

    # Bugs
    bugzilla_warning = false

    if params[:glsa][:bugs]
      bugs = params[:glsa][:bugs].map {|bug| bug.to_i }

      bugs.sort.each do |bug|
        begin
          b = Glsamaker::Bugs::Bug.load_from_id(bug)

          revision.bugs.create(
            :bug_id => bug,
            :title => b.summary,
            :whiteboard => b.status_whiteboard,
            :arches => b.arch_cc.join(', ')
          )
        rescue Exception => e
          log_error e
          logger.info { e.inspect }
          # In case of bugzilla errors, just keep the bug #
          revision.bugs.create(
            :bug_id => bug
          )
          bugzilla_warning = true
        end
      end
    end

    logger.debug params[:glsa][:package].inspect

    # Packages
    params[:glsa][:package].each do |package|
      logger.debug package.inspect
      next if package[:atom].strip == ''
      revision.packages.create(package)
    end

    # References
    refs = params[:glsa][:reference].sort { |a, b| a[:title] <=> b[:title] }
    refs.each do |reference|
      logger.debug reference.inspect
      next if reference[:title].strip == ''
      revision.references.create(reference)
    end

    # Comments
    @glsa.comments.each do |comment|
      comment.read = params["commentread-#{comment.id}"] == "true"
      comment.save
    end

    # Sending emails
    Glsamaker::Mail.edit_notification(@glsa, rev_diff(@glsa, @glsa.revisions[-2], revision), current_user)

    flash[:notice] = "Saving was successful. #{'NOTE: Bugzilla integration is not available, only plain bug numbers.' if bugzilla_warning}"
    redirect_to :action => 'show', :id => @glsa
    
  end

  def prepare_release
    @glsa = Glsa.find(params[:id])
    return unless check_object_access!(@glsa)

    if current_user.access < 2
      deny_access "Tried to prepare release"
      return
    end

    if @glsa.status == 'request'
      flash[:error] = 'You cannot release a request. Draft the advisory first.'
      redirect_to :action => "show", :id => @glsa
      return
    end

    if @glsa.restricted
      flash[:error] = 'You cannot release a confidential draft. Make it public first.'
      redirect_to :action => "show", :id => @glsa
      return
    end

    @rev = @glsa.last_revision

    @comments_override = (current_user.is_el_jefe? and params[:override_approvals].to_i == 1) || false
  end

  def release
    @glsa = Glsa.find(params[:id])
    return unless check_object_access!(@glsa)

    if current_user.access < 2
      deny_access "Tried to prepare release"
      return
    end

    if @glsa.status == 'request'
      flash[:error] = 'You cannot release a request. Draft the advisory first.'
      redirect_to :action => "show", :id => @glsa
      return
    end

    if @glsa.restricted
      flash[:error] = 'You cannot release a confidential draft. Make it public first.'
      redirect_to :action => "show", :id => @glsa
      return
    end

    @rev = @glsa.last_revision
    begin
      if current_user.is_el_jefe?
        @glsa.release!
      else
        @glsa.release
      end
      
      @glsa.invalidate_last_revision_cache

      if params[:email] == '1'
        of = @template_format
        @template_format = 'txt'
        Glsamaker::Mail.send_text(
            render_to_string({:template => 'glsa/show.txt.erb', :format => :txt, :layout => false}),
            "[ GLSA #{@glsa.glsa_id} ] #{@rev.title}",
            current_user,
            false
        )
        @template_format = of
      end
    rescue GLSAReleaseError => e
      flash[:error] = "Internal error: #{e.message}. Cannot release advisory."
      redirect_to :action => "show", :id => @glsa
      return
    end

    # ugly hack, but necessary to switch back to html
    @real_format = 'html'
    render(:format => :html, :layout => 'application')
  end

  def finalize_release
    @glsa = Glsa.find(params[:id])

    if params[:close_bugs] == '1'
      message = "GLSA #{@glsa.glsa_id}"
      with_format(:txt) do
        message = render_to_string :partial => 'close_msg'
      end
      
      @glsa.close_bugs(message)
    end
  end

  def diff
    @glsa = Glsa.find(params[:id])
    return unless check_object_access!(@glsa)
    
    rev_old = @glsa.revisions.find_by_revid(params[:old])
    rev_new = @glsa.revisions.find_by_revid(params[:new])
    
    @diff = with_format(:xml) { rev_diff(@glsa, rev_old, rev_new) }
  end

  def update_cache
    @glsa = Glsa.find(params[:id])
    return unless check_object_access!(@glsa)
    @rev = @glsa.last_revision
    
    @rev.update_cached_bug_metadata
    
    flash[:notice] = "Successfully updated all caches."
    if params[:redirect]
      redirect_to params[:redirect]
    else
      redirect_to :action => 'show', :id => @glsa unless params[:no_redirect]
    end
  rescue Exception => e
    log_error e
    flash[:notice] = "Could not update caches: #{e.message}"
    if params[:redirect]
      redirect_to params[:redirect]
    else
      redirect_to :action => 'show', :id => @glsa unless params[:no_redirect]
    end
  end

  def destroy
  end

  def comment
  end

  def import_references
    begin
      if params[:go].to_s == '1'
        glsa = Glsa.find(Integer(params[:id]))
        return unless check_object_access!(glsa)
        refs = []
        
        params[:import][:cve].each do |cve_id|
          cve = Cve.find_by_cve_id cve_id
          refs << {:title => cve.cve_id, :url => cve.url}
        end
        
        glsa.add_references refs
        
        flash[:notice] = "Imported #{refs.count} references."
        redirect_to :action => "show", :id => glsa.id
        return
      else
        @glsa = Glsa.find(Integer(params[:id]))
        return unless check_object_access!(@glsa)
        @cves = @glsa.related_cves
      end      
    rescue Exception => e
      render :text => "Error: #{e.message}", :status => 500
      log_error e
      return
    end
    
    render :layout => false
  end
  
  protected
  def rev_diff(glsa, rev_old, rev_new, format = :unified, context_lines = 3)
    @glsa = glsa
    @rev = rev_old
    old_text = Glsamaker::XML.indent(
      render_to_string(
        :template => 'glsa/_glsa.xml.builder',
        :locals => {:glsa => @glsa, :rev => @rev},
        :layout => 'none'import_references: rails-3 compat fix
      ),
      {:indent => 2, :maxcols => 80}
    )    
    
    @rev = rev_new
    new_text = Glsamaker::XML.indent(
      render_to_string(
        :template => 'glsa/_glsa.xml.builder',
        :locals => {:glsa => @glsa, :rev => @rev},
        :layout => 'none'
      ),
      {:indent => 2, :maxcols => 80}
    )

    Glsamaker::Diff.diff(old_text, new_text, format, context_lines)
  end
end