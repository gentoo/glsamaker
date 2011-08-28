class Admin::TemplatesController < ApplicationController
  before_filter :admin_access_required

  # GET /admin/templates
  # GET /admin/templates.json
  def index
    @templates = Template.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @templates }
    end
  end

  # GET /admin/templates/1
  # GET /admin/templates/1.json
  def show
    @template = Template.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @template }
    end
  end

  # GET /admin/templates/new
  # GET /admin/templates/new.json
  def new
    @template = Template.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @template }
    end
  end

  # GET /admin/templates/1/edit
  def edit
    @template = Template.find(params[:id])
  end

  # POST /admin/templates
  # POST /admin/templates.json
  def create
    @template = Template.new(params[:template])

    respond_to do |format|
      if @template.save
        format.html { redirect_to admin_template_path(@template), :notice => 'Template was successfully created.' }
        format.json { render :json => @template, :status => :created, :location => @template }
      else
        format.html { render :action => "new" }
        format.json { render :json => @template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /admin/templates/1
  # PUT /admin/templates/1.json
  def update
    @template = Template.find(params[:id])

    respond_to do |format|
      if @template.update_attributes(params[:template])
        format.html { redirect_to @template, :notice => 'Template was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/templates/1
  # DELETE /admin/templates/1.json
  def destroy
    @template = Template.find(params[:id])
    @template.destroy

    respond_to do |format|
      format.html { redirect_to admin_templates_url }
      format.json { head :ok }
    end
  end
end