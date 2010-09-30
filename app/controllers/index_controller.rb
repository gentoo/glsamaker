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

# Index controller
class IndexController < ApplicationController
  before_filter :login_required, :except => :error
  
  def index
    @my_drafts = Glsa.find(:all, :conditions => ["status = 'draft' AND submitter = ?", current_user.id], :order => "updated_at DESC", :limit => 10)
  end
  
  def error
    if params[:type] == "user"
      render :template => 'index/error-user', :layout => 'notice'
    elsif params[:type] == "disabled"
      render :template => 'index/error-disabled', :layout => 'notice'
    elsif params[:type] == "access"
      render :template => 'index/error-access', :layout => 'notice'
    else
      render :template => 'index/error-system', :layout => 'notice'
    end
  end
  
  def about
  end
  
  def profile
  end
  
end
