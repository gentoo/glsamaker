class Admin::IndexController < ApplicationController
  before_filter :admin_access_required
  
  def index
  end
end