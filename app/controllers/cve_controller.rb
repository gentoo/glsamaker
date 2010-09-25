class CveController < ApplicationController
  before_filter :login_required
  include ApplicationHelper
  include CveHelper

  def index
    @pageID = 'cve'
  end

  def list
    @pageID = 'cve'
    
    condition = view_mask_to_condition(params[:view_map].to_i)
    @cves = CVE.find(:all, :conditions => [condition], :limit => 1000, :order => 'cve_id DESC')
    
    respond_to do |format|
      format.html
      format.json {
        x = @cves.map {|cve| [cve.id, cve.colorize(:cve_id), CGI.escapeHTML(cve.summary), cve.state]}
        render :text => x.to_json }
    end
  end

  def info
    @cve = CVE.find(:first, :conditions => ['cve_id = ?', params[:id]])
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def show
  end

  def store
  end

  def bug_package
    cve_nums = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "File new Bug; CVElist: " + cve_nums.inspect }

    cves = cve_nums.map {|c| CVE.find(c) }
    cpes = cves.map {|c| c.cpes.map{|cpe| cpe.product } }.flatten.uniq
    
    package_hints = cves.map{|c| c.package_hints }.flatten.uniq.sort
    logger.debug { "CPE Products: " + cpes.inspect }
    logger.debug { "Package hints: " + package_hints.inspect }
    
    logger.debug { {:package_hints => package_hints}.to_json }
    render :json => {:package_hints => package_hints}.to_json
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def bug_preview
    cve_nums = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "File new Bug (preview); CVElist: " + cve_nums.inspect }

    @cve_ids = cve_nums.map {|c| CVE.find(c).cve_id }
    @cve_txt = CVE.concat(cve_nums)
    @package = params[:package]
    @maintainers = Glsamaker::Portage.get_maintainers(params[:package])
    render :layout => false
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500    
  end
  
  def bug
    cve_nums = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "File new Bug (final); CVElist: " + cve_nums.inspect }

    cves = cve_nums.map {|c| CVE.find(c) }
    
    data = {
      :product => 'Gentoo Security',
      :component => params[:bug_type] == 'true' ? 'Vulnerabilities' : 'Kernel',
      :summary => params[:bug_title],
      :assignee => 'security@gentoo.org'
    }
    
    cc = []
    if params[:cc_maint] == 'true'
      cc << Glsamaker::Portage.get_maintainers(params[:package])
    end
    
    cc << params[:cc_custom].split(',')
    data[:cc] = cc.join(',')
    
    comment = ""
    if params[:add_cves] == 'true'
      comment += CVE.concat(cve_nums)
    end
    
    if params[:add_comment] == 'true'
      comment += "\n" if params[:add_cves]
      comment += params[:comment]
    end
    data[:comment] = comment
    
    whiteboard = "%s %s" % [params[:wb_1], params[:wb_2]]
    whiteboard += " %s" % params[:wb_ext] unless params[:wb_ext] == ""
    
    data[:severity] = whiteboard_to_severity(whiteboard)
    
    bugnr = -1
    begin
      bugnr = Bugzilla.file_bug(data)
      Bugzilla.update_bug(bugnr, {:whiteboard => whiteboard})
    rescue Exception => e
      raise "Filing the bug failed. Check if the accounts in CC actually exist."
    end
    
    logger.info "Filed bug #{bugnr} on behalf of user #{current_user.login}."
    
    cves.each {|cve| cve.assign(bugnr, current_user, :file) }
    
    render :text => 'ok'
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500    
  end

  def assign_preview
    bug_id = Integer(params[:bug])
    cves = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "Assign Bug: #{bug_id} CVElist: " + cves.inspect }

    cve_ids = cves.map {|c| CVE.find(c).cve_id }
    logger.debug { cve_ids.inspect }

    @cve_txt = CVE.concat(cves)
    @bug = Glsamaker::Bugs::Bug.load_from_id(bug_id)
    @summary = cveify_bug_title(@bug.summary, cve_ids)

    render :layout => false
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def assign
    bug_id = Integer(params[:bug])
    cves = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "Assign Bug: #{bug_id} CVElist: " + cves.inspect }

    cves.each {|cve_id| CVE.find(cve_id).assign(bug_id, current_user, :assign) }

    if params[:comment] or params[:summary]
      bug = Glsamaker::Bugs::Bug.load_from_id(bug_id)
      cve_ids = cves.map {|c| CVE.find(c).cve_id }
      changes = {}

      changes[:comment] = CVE.concat(cves) if params[:comment]
      changes[:summary] = cveify_bug_title(bug.summary, cve_ids)
      Bugzilla.update_bug(bug_id, changes)
    end

    render :text => "ok"
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def nfu
    @cves = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "NFU CVElist: " + @cves.inspect + " Reason: " + params[:reason] }

    @cves.each do |cve_id|
      CVE.find(cve_id).nfu(current_user, params[:reason])
    end

    render :text => "ok"
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def commit
  end

end
