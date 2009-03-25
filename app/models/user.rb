class User < ActiveRecord::Base
  has_and_belongs_to_many :permissions
  
  has_many :submitted_glsas, :class_name => "Glsa", :foreign_key => "submitter"
  has_many :requested_glsas, :class_name => "Glsa", :foreign_key => "requester"
  has_many :bugreadymade_glsas, :class_name => "Glsa", :foreign_key => "bugreadymaker"

  validates_uniqueness_of :login, :message => "User name must be unique"
  validates_presence_of :login, :message => "User name can't be blank"
  
  validates_format_of :email, :with => /[\w.%+-]+?@[\w.-]+?\.\w{2,6}$/, :message => "Invalid Email address format"
end
