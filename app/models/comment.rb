# ===GLSAMaker v2
#  Copyright (C) 2009-2011 Alex Legler <a3li@gentoo.org>
#  Copyright (C) 2009 Pierre-Yves Rofes <py@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

# Comment model
class Comment < ActiveRecord::Base
  belongs_to :glsa, :class_name => "Glsa", :foreign_key => "glsa_id"
  belongs_to :user

  include ActiveModel::Validations
  validates :glsa_id, :presence => true
  validates :user_id, :presence => true
  validates :rating, :inclusion => { :in => %w[neutral approval rejection]}
  validates :rating, :uniqueness => { :scope => [:glsa_id, :user_id], :if => Proc.new {|comment| comment.rating != 'neutral'}, :message => 'You have already approved or rejected this draft' }

  class CommentValidator < ActiveModel::Validator
    def validate(record)
      if record.glsa.is_owner? record.user
        if record.rating != 'neutral'
          record.errors[:rating] << 'The owner of a draft cannot make approvals or rejections'
        end
      end

      if record.glsa.submitter.nil?
        record.errors[:rating] << 'You may not approve or reject advisories that have not been filled in yet'
      end

      if record.user.access < 2
        if record.rating != 'neutral'
          record.errors[:rating] << 'You may not approve or reject drafts'
        end
      end
    end
  end

  validates_with CommentValidator
end
