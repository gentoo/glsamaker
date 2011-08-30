class CveComment < ActiveRecord::Base
  belongs_to :cve
  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  
  define_index do
    indexes comment
    has user_id, cve_id
  end
end