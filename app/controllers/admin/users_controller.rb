class Admin::UsersController < ApplicationController
  def index
    @users = User.find(:all, :conditions => 'id > 0')
  end
  
  def show  
    @user = User.find(params[:id])
    
    if @user.id == 0
      flash[:error] = "That's the system account."
      redirect_to(admin_users_path)
      return
    end
  end

  def create
    @user = User.new(params[:user])
    
    if @user.save
      redirect_to(admin_user_path(@user), :notice => 'User was successfully created.')
    else
      render :action => "new"
    end
  end

  def new
    @user = User.new
  end

  def edit
    @user = User.find(params[:id])

    if @user.id == 0
      flash[:error] = "That's the system account."
      redirect_to(admin_users_path)
      return
    end    
  end

  def update
    @user = User.find(params[:id])

    if @user.id == 0
      flash[:error] = "That's the system account."
      redirect_to(admin_users_path)
      return
    end

    if @user.update_attributes(params[:user])
      redirect_to(admin_user_path(@user), :notice => 'User was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    @user = User.find(params[:id])
    
    if @user.id == 0
      flash[:error] = "That's the system account."
      redirect_to(admin_users_path)
      return
    end    
    
    @user.destroy
    flash[:notice] = "User was successfully deleted."
    redirect_to(admin_users_path)
  end

end
