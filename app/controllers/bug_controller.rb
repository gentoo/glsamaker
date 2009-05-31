# ===GLSAMaker v2
#  Copyright (C) 2009 Alex Legler <a3li@gentoo.org>
#  Copyright (C) 2009 Pierre-Yves Rofes <py@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

class BugController < ApplicationController
  def bug
    begin
      @bug = Glsamaker::Bugs::Bug.load_from_id(params[:id].to_i)
    rescue SocketError => e
      @bug = "down"
    rescue ArgumentError => e
      @bug = nil
    end
    
    render :layout => false
  end

  def history
    begin
      @bug = Glsamaker::Bugs::Bug.load_from_id(params[:id].to_i)
    rescue SocketError => e
      @bug = "down"
    rescue ArgumentError => e
      @bug = nil
    end
    
    render :layout => false
  end

end
