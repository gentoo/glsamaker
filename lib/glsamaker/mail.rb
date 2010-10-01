# ===GLSAMaker v2
#  Copyright (C) 2010 Alex Legler <a3li@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

module Glsamaker
  module Mail
    module_function
    def edit_notification(glsa, diff, user)
      if GLSAMAKER_NO_EMAIL
        Rails.logger.info "Not sending email."
        return false
      end
      
      User.find(:all, :conditions => 'id > 0').each do |rcpt|
        next unless rcpt.can_access? glsa
        
        unless user.get_pref_category(:mail)[:edit] == false
          GlsaMailer.deliver_edit(rcpt, glsa, diff, user)
        end
      end
    end
    
    def request_notification(glsa, user)
      if GLSAMAKER_NO_EMAIL
        Rails.logger.info "Not sending email."
        return false
      end
      
      User.find(:all, :conditions => 'id > 0').each do |rcpt|
        next unless rcpt.can_access? glsa        
        
        unless user.get_pref_category(:mail)[:request] == false
          GlsaMailer.deliver_request(rcpt, glsa, user)
        end
      end
    end    
    
  end
end
