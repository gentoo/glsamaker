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

  def commit
  end

end
