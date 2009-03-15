class Comment < ActiveRecord::Base
  belongs_to :Glsa, :class_name => "Glsa", :foreign_key => "glsa_id"
end
