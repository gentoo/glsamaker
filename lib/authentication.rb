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

# Authentication module
module Authentication
  protected
    # Login filter to be applied to *all* pages on GLSAMaker
    def login_required
      # Production authentication via REMOTE_USER
      if Rails.env.production? or GLSAMAKER_FORCE_PRODUCTION_AUTH
        # REMOTE_USER should be there in FCGI or Passenger
        env_user_name = user_name
      
        # Autentication system most likely broken
        if env_user_name.nil?
          logger.warn "Neither REMOTE_USER nor HTTP_AUTHORIZATION set in environment."
          redirect_to :controller => 'index', :action => 'error', :type => 'system'
          return
        end

        user = User.find_by_login(env_user_name)
        
        # User not known to GLSAMaker
        if user == nil
          logger.warn "Unknown user #{env_user_name} tried to log in from #{request.remote_ip}"
          redirect_to :controller => 'index', :action => 'error', :type => 'user'
          return
        end

        # User is marked as disabled in the DB
        if user.disabled
          logger.warn "Disabled user #{env_user_name} tried to log in from #{request.remote_ip}"
          redirect_to :controller => 'index', :action => 'error', :type => 'disabled'
          return
        end

        # Auth is fine now.
        logger.debug "Environment username: #{env_user_name}"

      # For all other environments request, HTTP auth by ourselves
      # The password can be set in config/initializers/glsamaker.rb
      else
        authenticate_or_request_with_http_basic("GLSAMaker testing environment") do |username, password|
          logger.debug "Environment username: #{username}"
          check_auth(username, password)
        end
      end
    end

    # Filter for admin pages
    def admin_access_required
      unless current_user.is_el_jefe?
        deny_access "Admin interface"
        false
      end
    end
    
    # Returns the ActiveRecord object of the currently logged in user
    def current_user
      User.find_by_login(user_name)
    end
    
    # Populate user to views, shamelessly stolen from restful auth. ;)
    def self.included(base)
      base.send :helper_method, :current_user if base.respond_to? :helper_method
    end
    
  private
    # Tries to find out the user name used for HTTP auth from two sources
    def user_name
      if request.env.include?('REMOTE_USER') then
        u = request.env['REMOTE_USER']
        return u unless u.nil?
      else
        auth = http_authorization_data
        return auth[0] unless auth.nil?
      end
      return nil
    end
    
    def check_auth(username, password)
      user = User.find_by_login(username)
      
      return false if user.nil?
      return false if user.disabled
      
      password == GLSAMAKER_DEVEL_PASSWORD
    end
  
    def http_authorization_data
      return nil unless request.env.include?('HTTP_AUTHORIZATION')
      return nil if request.env['HTTP_AUTHORIZATION'].nil?
      
      auth_info = request.env['HTTP_AUTHORIZATION'].split
      
      if auth_info[0] == "Basic"
        auth_info[1].unpack("m*").first.split(/:/, 2)
      else
        logger.fatal "Non-Basic HTTP authentication given. I can't process that"
        raise RuntimeError, "Cannot process this type of HTTP authentication"
      end
    end
end
