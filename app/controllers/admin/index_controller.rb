class Admin::IndexController < ApplicationController
  before_filter :check_access
  
  def index
  end


  protected
  def check_access
    # Contributor, no foreign drafts
    unless current_user.is_el_jefe?
      deny_access "Administration interface #{params[:action]})"
      return false
    end
  end
end
