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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  include Authentication
  include ApplicationHelper

  before_filter :login_required

  protected
  # Checks access to a given GLSA
  def check_object_access(glsa)
    # Contributor, no foreign drafts
    if current_user.access == 0
      unless glsa.is_owner? current_user
        deny_access "Access to GLSA #{glsa.id} (#{params[:action]})"
        return false
      end
    elsif current_user.access == 1
      if glsa.restricted
        deny_access "Access to restricted GLSA #{glsa.id} (#{params[:action]})"
        return false
      end
    end

    true
  end

  def deny_access(msg)
    logger.warn "[#{Time.now.rfc2822}] UNAUTHORIZED ACCESS by #{current_user.login} from #{request.remote_ip} to #{request.url}: #{msg}"
    redirect_to :controller => '/index', :action => 'error', :type => 'access'
  end
  
  def log_error(error)
    caller[0] =~ /`([^']*)'/ and where = $1
    logger.error "[#{where}] #{error.class}: #{error.to_s}"
    logger.info error.backtrace.join("\n")
  end
end
