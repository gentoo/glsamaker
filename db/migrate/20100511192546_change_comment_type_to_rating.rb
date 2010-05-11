class ChangeCommentTypeToRating < ActiveRecord::Migration
  def self.up
    rename_column :comments, :type, :rating
  end

  def self.down
    rename_column :comments, :rating, :type
  end
end
