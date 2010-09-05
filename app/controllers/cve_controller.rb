class CveController < ApplicationController
  before_filter :login_required
  include ApplicationHelper

  def index
    @pageID = 'cve'
  end

  def list
    @pageID = 'cve'
    @cves = CVE.find(:all, :conditions => ['state = ?', 'NEW'], :limit => 100)

    respond_to do |format|
      format.html
      format.json {
        x = @cves.map {|cve| [cve.id, cve.cve_id, cve.summary, cve.state]}
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
    render :text => e.message, :status => 500
  end

  def assign
    bug_id = Integer(params[:bug])
    cves = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "Assign Bug: #{bug_id} CVElist: " + cves.inspect }

    cves.each do |cve_id|
      cve = CVE.find cve_id
      assi = cve.assignments.new
      assi.bug = bug_id
      assi.save!

      ch = cve.cve_changes.new
      ch.user = current_user
      ch.action = 'assign'
      ch.object = assi.id
      ch.save!

      cve.state = "ASSIGNED"
      cve.save!
    end

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
    render :text => e.message, :status => 500
  end

  def nfu
    @cves = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "NFU CVElist: " + @cves.inspect + " Reason: " + params[:reason] }

    @cves.each do |cve_id|
      cve = CVE.find(cve_id)
      raise unless cve

      cve.state = "NFU"
      cve.save!

      ch = cve.cve_changes.new
      ch.user = current_user
      ch.action = 'nfu'
      ch.object = params[:reason] if params[:reason] and not params[:reason].empty?
      ch.save!
    end

    render :text => "ok"
  rescue Exception => e
    render :text => e.message, :status => 500
  end

  def commit
  end

end
