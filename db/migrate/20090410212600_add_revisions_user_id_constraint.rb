class AddRevisionsUserIdConstraint < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE `revisions` ADD CONSTRAINT revisions_user_userid FOREIGN KEY (user_id) REFERENCES users (id)"
  end

  def self.down
    execute "ALTER TABLE `revisions` DROP FOREIGN KEY revisions_user_userid"
  end
end
