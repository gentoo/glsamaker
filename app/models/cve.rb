class CVE < ActiveRecord::Base
  has_many :references, :class_name => "CVEReference"
  has_many :comments, :class_name => "CVEComment"
end
