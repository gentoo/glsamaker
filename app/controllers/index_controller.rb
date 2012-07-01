# ===GLSAMaker v2
#  Copyright (C) 2009-2011 Alex Legler <a3li@gentoo.org>
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
  skip_before_filter :login_required, :only => [:error]
  
  def index
    @my_drafts = Glsa.where(:status => 'draft', :submitter => current_user.id).order("updated_at DESC").limit(10)
    @pageTitle = "Welcome"
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
    @pageTitle = "About GLSAMaker 2"
  end
  
  def profile
    @user = current_user
    @prefs = @user.preferences
  end
  
  def update
    @user = current_user
    @prefs = @user.preferences

    preferences = {:own_ready => false, :own_comment => false, :edit => false, :new_req => false, :not_me => false}

    unless params[:preferences] == nil
      %w[own_ready own_comment edit new_req not_me].each do |notification|
        preferences[notification.to_sym] = params[:preferences][notification] == '1'
      end
    end
    
    @user.preferences[:mail] ||= {}
    @user.preferences[:mail] = preferences
    if @user.save
      flash[:notice] = "Successfully updated your profile"
      redirect_to :action => "index"
    else
      flash[:error] = "Could not update your profile"
      render :action => "profile"
    end
  end
  
end
