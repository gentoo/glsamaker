class AddUserIdToRevisions < ActiveRecord::Migration
  def self.up
    add_column :revisions, :user_id, :integer
  end

  def self.down
    remove_column :revisions, :user_id
  end
end
