class CveController < ApplicationController
  before_filter :login_required
  
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


  def nfu
    @cves = params[:cves].split(',').map{|cve| Integer(cve)}
    logger.debug { "NFU CVElist: " + @cves.inspect }
    
    @cves.each do |cve_id|
      cve = CVE.find(cve_id)
      raise unless cve
      
      cve.state = "NFU"
      cve.save!
      
      ch = CVEChange.new
      ch.user = current_user
      ch.cve = cve
      ch.action = 'nfu'
      ch.save!
    end
    
    render :text => "ok"
  rescue Exception => e
    render :text => e.message, :status => 500
  end

  def commit
  end

end
