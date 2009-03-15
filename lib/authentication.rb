module Authentication
  protected
    def login_required
      # Production authentication via REMOTE_USER
      if RAILS_ENV == "production"
        # Autentication system most likely broken
        if request.env['REMOTE_USER'].nil?
          redirect_to :controller => 'index', :action => 'error', :type => 'system'
          return
        end

        user = User.find_by_login(request.env['REMOTE_USER'])

        # User not known to GLSAMaker
        if user.nil?
         redirect_to :controller => 'index', :action => 'error', :type => 'user'
         return
        end

        # User is marked as disabled in the DB
        if user.disabled
          redirect_to :controller => 'index', :action => 'error', :type => 'disabled'
          return
        end

        # Auth is fine now.

      # For all other environments request, HTTP auth by ourselves
      # The password can be set in config/initializers/glsamaker.rb
      else
        authenticate_or_request_with_http_basic("GLSAMaker testing environment") do |username, password|
          user = User.find_by_login(user)

          return false if user.nil?
          return false if user.disabled

          password == GLSAMAKER_DEVEL_PASSWORD
        end
      end
    end
    
    def current_user
    end
end
