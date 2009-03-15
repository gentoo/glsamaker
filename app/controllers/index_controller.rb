class IndexController < ApplicationController
  before_filter :login_required, :except => :error
  
  def index
    render :text => request.env.inspect
  end
  
  def error
    if params[:type] == "user"
      render :template => 'index/error-user', :layout => 'notice'
    elsif params[:type] == "disabled"
      render :template => 'index/error-disabled', :layout => 'notice'
    else
      render :template => 'index/error-system', :layout => 'notice'
    end
  end
  
end
