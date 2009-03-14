class Permission < ActiveRecord::Base
  has_and_belongs_to_many :users
  
  validates_uniqueness_of :name, :message => "Permission name must be unique"
  validates_presence_of :name, :message => "Name can't be blank"
  validates_presence_of :title, :message => "Title can't be blank"
end
