class CVEChange < ActiveRecord::Base
  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  belongs_to :cve, :class_name => "CVE", :foreign_key => "cve_id"
end
