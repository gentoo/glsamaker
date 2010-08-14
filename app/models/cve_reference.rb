class CVEReference < ActiveRecord::Base
  belongs_to :cve, :class_name => "CVE", :foreign_key => "cve_id"
end
