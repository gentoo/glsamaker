class Api::GlsaController < ApplicationController
  layout false

  # Limited to creating requests for now
  def create
    @glsa = nil

    if params[:type] == 'request'
      @glsa = Glsa.new_request(params[:title], params[:bugs], params[:comment], params[:access], (params[:import_references].to_i == 1), current_user)
      Glsamaker::Mail.request_notification(@glsa, current_user)
    end

    respond_to do |format|
      if @glsa and @glsa.save
        format.json { render :json => @glsa, :status => :created }
      else
        format.json { render :json => @glsa ? @glsa.errors : ['error: unknown action'], :status => :unprocessable_entity }
      end
    end
  end

end
