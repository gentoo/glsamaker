module Authentication
  protected
  
    def login_required
      authenticate_or_request_with_http_basic("GLSAMaker") do |username, password|        
        (username == "user" && password == "foo")
      end
    end
    
    def current_user
    end
end