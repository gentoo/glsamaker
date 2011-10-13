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
  include Authorization
  include ApplicationHelper

  before_filter :login_required

  protected
  def log_error(error)
    caller[0] =~ /`([^']*)'/ and where = $1
    logger.error "[#{where}] #{error.class}: #{error.to_s}"
    logger.info error.backtrace.join("\n")
    ExceptionNotifier::Notifier.exception_notification(request.env, error).deliver
  end
end
