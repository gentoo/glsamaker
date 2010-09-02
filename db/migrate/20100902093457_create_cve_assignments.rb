class CreateCveAssignments < ActiveRecord::Migration
  def self.up
    create_table :cve_assignments do |t|
      t.integer :cve_id
      t.integer :bug
      t.timestamps
    end
    
    add_index :cve_assignments, :cve_id
    add_index :cve_assignments, :bug
    
    execute "ALTER TABLE cve_assignments ADD CONSTRAINT cve_assignments_cve_id FOREIGN KEY (cve_id) REFERENCES cves (id)"
  end

  def self.down
    execute "ALTER TABLE cve_assignments DROP FOREIGN KEY cve_assignments_cve_id"
    
    remove_index :cve_assignments, :bug
    remove_index :cve_assignments, :cve_id

    drop_table :cve_assignments
  end
end
