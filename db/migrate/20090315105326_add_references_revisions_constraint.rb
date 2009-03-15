class AddReferencesRevisionsConstraint < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE `references` ADD CONSTRAINT references_revisions_revisionid FOREIGN KEY (revision_id) REFERENCES revisions (id)"
  end

  def self.down
    execute "ALTER TABLE `references` DROP FOREIGN KEY references_revisions_revisionid"
  end
end
