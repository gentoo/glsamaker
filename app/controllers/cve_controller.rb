class CveController < ApplicationController
  include ApplicationHelper
  include CveHelper

  before_filter :check_access, :except => [:info, :general_info, :references, :packages, :comments, :changes]

  def index
    @pageID = 'cve'
  end

  def list
    @pageID = 'cve'

    condition = view_mask_to_condition(params[:view_map].to_i)
    @cves = Cve.where(condition).limit(1000).order('cve_id DESC')

    respond_to do |format|
      format.html
      format.json {
        x = @cves.map {|cve| [cve.id, cve.colorize(:cve_id), CGI.escapeHTML(cve.summary), cve.state]}
        render :text => x.to_json }
    end
  end

  def bug_package
    cve_nums = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "File new Bug; CVElist: " + cve_nums.inspect }

    cves = cve_nums.map {|c| Cve.find(c) }
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

    @cve_ids = cve_nums.map {|c| Cve.find(c).cve_id }
    @cve_txt = Cve.concat(cve_nums)
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

    cves = cve_nums.map {|c| Cve.find(c) }

    data = {
      :product => 'Gentoo Security',
      :component => params[:bug_type] == 'true' ? 'Vulnerabilities' : 'Kernel',
      :summary => params[:bug_title],
      :assignee => 'security@gentoo.org'
    }

    cc = []
    if params[:cc_maint] == 'true'
      cc += Glsamaker::Portage.get_maintainers(params[:package])
    end

    cc += params[:cc_custom].split(',')
    data[:cc] = cc.compact.delete_if {|i| i == ''}

    comment = ""
    if params[:add_cves] == 'true'
      comment += Cve.concat(cve_nums)
    end

    if params[:add_comment] == 'true'
      comment += "\n" if params[:add_cves]
      comment += params[:comment]
    end
    data[:comment] = comment

    whiteboard = ""
    if params[:bug_type] == 'true' # If the bug is not a kernel issue
      whiteboard += "%s %s" % [params[:wb_1], params[:wb_2]]
      whiteboard += " %s" % params[:wb_ext] unless params[:wb_ext] == ""
    else
      whiteboard = params[:wb_ext]
    end

    data[:severity] = whiteboard_to_severity(whiteboard)
    data[:version] = 'unspecified'
    data[:status] = 'IN_PROGRESS'

    bugnr = -1
    begin
      bugnr = Bugzilla.file_bug(data)
      Bugzilla.update_bug(bugnr, {:whiteboard => whiteboard})
    rescue Exception => e
      log_error e
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

    cve_ids = cves.map {|c| Cve.find(c).cve_id }
    logger.debug { cve_ids.inspect }

    @cve_txt = Cve.concat(cves)
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

    if params[:comment] or params[:summary]
      bug = Glsamaker::Bugs::Bug.load_from_id(bug_id)
      cve_ids = cves.map {|c| Cve.find(c).cve_id }
      changes = {}

      changes[:comment] = Cve.concat(cves) if params[:comment] == 'true'
      changes[:summary] = cveify_bug_title(bug.summary, cve_ids) if params[:summary] == 'true'
      Bugzilla.update_bug(bug_id, changes)
    end

    cves.each {|cve_id| Cve.find(cve_id).assign(bug_id, current_user, :assign) }

    render :text => "ok"
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def new
    @cve = Cve.create(cve_id: params[:cve_id], summary: params[:summary], state: 'NEW')
    render :text => "ok"
    rescue Exception => e
      log_error e
      respond_to do |format|
        format.html { flash.now[:error] = 'Filing the CVE failed. Is this a duplicate?' }
        format.js {
          raise 'Filing the CVE failed. Is this a dupliate?'
          render :text => e.message, :status => 500
        }
      end
  end

  def nfu
    @cves = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "NFU CVElist: " + @cves.inspect + " Reason: " + params[:reason] }

    @cves.each do |cve_id|
      Cve.find(cve_id).nfu(current_user, params[:reason])
    end

    render :text => "ok"
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def note
    @cves = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "Note CVElist: " + @cves.inspect + " Note: " + params[:note] }

    @cves.each do |cve_id|
      Cve.find(cve_id).add_comment(current_user, params[:note])
    end

    render :text => "ok"
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def invalid
    @cves = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "Invalid CVElist: " + @cves.inspect + " Reason: " + params[:reason] }

    @cves.each do |cve_id|
      Cve.find(cve_id).invalidate(current_user, params[:reason])
    end

    render :text => "ok"
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def later
    @cves = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "LATER CVElist: " + @cves.inspect + " Reason: " + params[:reason] }

    @cves.each do |cve_id|
      Cve.find(cve_id).later(current_user, params[:reason])
    end

    render :text => "ok"
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  # Popup methods
  def info
    @cve = Cve.where(:cve_id => params[:id]).first
  end

  def general_info
    @cve = Cve.where(:cve_id => params[:cve_id]).first

    render :layout => false
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def references
    @cve = Cve.where(:cve_id => params[:cve_id]).first
    raise "Cannot find CVE" if @cve == nil

    render :layout => false
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def packages
    @cve = Cve.where(:cve_id => params[:cve_id]).first
    raise "Cannot find CVE" if @cve == nil

    @package_hints = @cve.package_hints

    logger.debug @package_hints.inspect

    render :layout => false
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def comments
    @cve = Cve.where(:cve_id => params[:cve_id]).first
    raise "Cannot find CVE" if @cve == nil

    render :layout => false
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def changes
    @cve = Cve.where(:cve_id => params[:cve_id]).first
    raise "Cannot find CVE" if @cve == nil

    render :layout => false
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def actions
    @cve = Cve.where(:cve_id => params[:cve_id]).first
    raise "Cannot find CVE" if @cve == nil

    render :layout => false
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  def mark_new
    @cve = Cve.where(:cve_id => params[:cve_id]).first

    @cve.mark_new(current_user)
    render :text => "ok"
  rescue Exception => e
    log_error e
    render :text => e.message, :status => 500
  end

  protected
  def check_access
    if current_user.access < 2
      deny_access "User has no access to the CVEtool"
      return false
    end
  end

end
