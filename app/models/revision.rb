class Revision < ActiveRecord::Base
  belongs_to :Glsa, :class_name => "Glsa", :foreign_key => "glsa_id"
  has_one :Glsa, :class_name => "Glsa", :foreign_key => "glsa_id"
  
  has_many :references
end
