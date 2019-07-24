# ===GLSAMaker v2
#  Copyright (C) 2011 Alex Legler <a3li@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

# Authorization module
module Authorization
  # Checks access to a given GLSA
  def check_object_access(glsa)
    # Contributor, no foreign drafts
    if current_user.access == 0
      unless glsa.is_owner? current_user
        return false
      end
    elsif current_user.access < 3
      if glsa.restricted
        return false
      end
    end

    true
  end

  # Checks access to a given GLSA, and aborts the request if the user does not have sufficient permissions
  def check_object_access!(glsa)
    unless check_object_access(glsa)
      deny_access "Access to restricted GLSA #{glsa.id} (#{params[:action]})"
      return false
    end

    true
  end

  # Redirects the user to a 'Access Denied' screen and logs the incident
  def deny_access(msg)
    log_unauthorized_access msg
    redirect_to :controller => '/index', :action => 'error', :type => 'access'
  end

  # Logs an unauthorized access attempt
  def log_unauthorized_access(msg)
    logger.warn "[#{Time.now.rfc2822}] UNAUTHORIZED ACCESS by #{current_user.login} from #{request.remote_ip} to #{request.url}: #{msg}"
  end
end
