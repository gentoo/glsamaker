# ===GLSAMaker v2
#  Copyright (C) 2011 Alex Legler <a3li@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

# BugsController handles bugs attached to GLSAs
class BugsController < ApplicationController
  layout false

  def new
    begin
      @glsa = Glsa.find(Integer(params[:glsa_id]))
      @bug = Bug.new
    rescue Exception
      @glsa = nil
    end
  end

  def create
    @glsa = Glsa.find(params[:glsa_id].to_i)
    return unless check_object_access!(@glsa)

    unless @glsa.nil?
      @added_bugs = []
      Bugzilla::Bug.str2bugIDs(params[:addbugs]).map do |bugid|
        begin
          @added_bugs << Glsamaker::Bugs::Bug.load_from_id(bugid)
        rescue Exception => e
          # Silently ignore invalid bugs
        end
      end

      begin
        @bugs_text = render_to_string :partial => '/glsa/edit_bug_row', :collection => @added_bugs, :as => :bug
      rescue Exception => e
        @error = "Error: #{e.message}"
        log_error e
      end
    else
      @error = "Cannot find GLSA"
    end

    respond_to do |format|
      format.html { render :status => 500 }
      format.js
    end
  end

  def destroy
  end

  def show
  end
end