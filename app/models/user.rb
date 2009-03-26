# Access levels
# +---+---------------------+------------------------------------------------+
# | # | Description         | Permissions                                    |
# +---+---------------------+------------------------------------------------+
# | 0 | Contributor         | can see own drafts, can fill in requests       |
# | 1 | Padawan             | all of the above, plus see and edit all drafts |
# | 2 | Full member         | all of the above, plus voting                  |
# | 3 | Confidential member | all of the above, including restricted drafts  |
# +---+---------------------+------------------------------------------------+
class User < ActiveRecord::Base
  has_and_belongs_to_many :permissions
  
  has_many :submitted_glsas, :class_name => "Glsa", :foreign_key => "submitter"
  has_many :requested_glsas, :class_name => "Glsa", :foreign_key => "requester"
  has_many :bugreadymade_glsas, :class_name => "Glsa", :foreign_key => "bugreadymaker"

  validates_uniqueness_of :login, :message => "User name must be unique"
  validates_presence_of :login, :message => "User name can't be blank"

  validates_presence_of :access, :message => "Access level needed"
  validates_numericality_of :access, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 3, :message => "Access levels must be (0..3)"
  
  validates_format_of :email, :with => /[\w.%+-]+?@[\w.-]+?\.\w{2,6}$/, :message => "Invalid Email address format"
end
