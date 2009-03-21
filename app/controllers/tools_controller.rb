class ToolsController < ApplicationController
  def buginfo
#    bug = Bugzilla::Bug.load_from_id(params[:id])
    
    str = "<dev-ruby/rails-2.2.2: XSS (CVE 2009-5607)"
    
    respond_to do |format|
      format.html { }
      format.ajax { render :text => "text to render...", :status => 1 }
    end
  end
  
  def ajaxbugs
    bug_ids = Bugzilla::Bug.str2bugIDs(params[:bugs])
    
    @bugs = []
    bug_ids.each do |bug_id|
      begin
        @bugs << Bugzilla::Bug.load_from_id(bug_id.to_i)
      rescue Exception => e
        @bugs << "Errorneous ID #{CGI.escapeHTML(bug_id)}, ignoring."
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

end
