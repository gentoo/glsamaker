class User < ActiveRecord::Base
  validates_uniqueness_of :login, :message => "User name must be unique"
  validates_presence_of :login, :message => "User name can't be blank"
  
  validates_format_of :email, :with => /[\w.%+-]+?@[\w.-]+?\.\w{2,6}$/, :message => "Invalid Email address format"
  
end
