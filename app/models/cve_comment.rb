class CveComment < ActiveRecord::Base
  belongs_to :cve
  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
end
