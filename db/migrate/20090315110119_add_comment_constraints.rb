class AddCommentConstraints < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE comments ADD CONSTRAINT comments_users_userid FOREIGN KEY (user_id) REFERENCES users (id)"
    execute "ALTER TABLE comments ADD CONSTRAINT comments_glsas_glsaid FOREIGN KEY (glsa_id) REFERENCES glsas (id)"
  end

  def self.down
    execute "ALTER TABLE comments DROP FOREIGN KEY comments_users_userid"
    execute "ALTER TABLE comments DROP FOREIGN KEY comments_glsas_glsaid"
  end
end
