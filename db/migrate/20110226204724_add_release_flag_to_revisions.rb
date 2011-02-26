class AddReleaseFlagToRevisions < ActiveRecord::Migration
  def self.up
    add_column :revisions, :is_release, :boolean, :default => false
    add_column :revisions, :release_revision, :integer
  end

  def self.down
    remove_column :revisions, :release_revision
    remove_column :revisions, :is_release
  end
end