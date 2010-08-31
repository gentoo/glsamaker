class CreateCveChanges < ActiveRecord::Migration
  def self.up
    create_table :cve_changes do |t|
      t.integer :cve_id
      t.integer :user_id
      t.string :action
      t.string :object
      t.timestamps
    end
    
    execute "ALTER TABLE cve_changes ADD CONSTRAINT cve_changes_cve_id FOREIGN KEY (cve_id) REFERENCES cves (id)"
    execute "ALTER TABLE cve_changes ADD CONSTRAINT cve_changes_user_id FOREIGN KEY (user_id) REFERENCES users (id)"
  end

  def self.down
    execute "ALTER TABLE cve_changes DROP FOREIGN KEY cve_changes_cve_id"
    execute "ALTER TABLE cve_changes DROP FOREIGN KEY cve_changes_user_id"
    drop_table :cve_changes
  end
end
