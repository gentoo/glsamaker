class Revision < ActiveRecord::Base
  belongs_to :glsa, :class_name => "Glsa", :foreign_key => "glsa_id"
  has_many :bugs
  has_many :references
end
