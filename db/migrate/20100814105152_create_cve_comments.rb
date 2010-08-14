class CreateCveComments < ActiveRecord::Migration
  def self.up
    create_table :cve_comments do |t|
      t.integer :cve_id
      t.integer :user_id
      t.boolean :confidential, :default => false
      t.text :comment
      t.timestamps
    end
    
    add_index :cve_comments, :cve_id
    execute "ALTER TABLE cve_comments ADD CONSTRAINT cve_comments_cve_id FOREIGN KEY (cve_id) REFERENCES cves (id)"
    execute "ALTER TABLE cve_comments ADD CONSTRAINT cve_comments_user_id FOREIGN KEY (user_id) REFERENCES users (id)"
  end

  def self.down
    execute "ALTER TABLE cve_comments DROP FOREIGN KEY cve_comments_cve_id"
    execute "ALTER TABLE cve_comments DROP FOREIGN KEY cve_comments_user_id"
    drop_table :cve_comments
  end
end
