# ===GLSAMaker v2
#  Copyright (C) 2011 Alex Legler <a3li@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

# CommentController handles comments made for GLSAs
class CommentsController < ApplicationController
  layout false
  
  def new
    begin
      @glsa = Glsa.find(Integer(params[:glsa_id]))
      @comment = Comment.new
    rescue Exception => e
      @glsa = nil
    end
  end

  def create
    @glsa = Glsa.find(params[:glsa_id].to_i)

    unless @glsa.nil?
      comment_data = params[:newcomment]
      comment = nil

      if comment_data['text'].strip != ''
        comment = @glsa.comments.build(comment_data)
        comment.user = current_user

        if comment.save
          Glsamaker::Mail.comment_notification(@glsa, comment, current_user)

          if @glsa.is_approved? and @glsa.approvals.count ==  @glsa.rejections.count + 2
            Glsamaker::Mail.approval_notification(@glsa)
          end
        else
          @error = comment.errors
          render
          return
        end
      end

      begin
        @comment_number = @glsa.comments.count
        @comment_text = render_to_string :partial => "/glsa/comment", :object => comment
      rescue Exception => e
        @error = "Error: #{e.message}"
      end
    else
      @error = "Error: Cannot find GLSA"
    end
  end

  def show
  end

  def destroy
  end

end
