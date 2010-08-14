class CreateCpes < ActiveRecord::Migration
  def self.up
    create_table :cpes do |t|
      t.string :cpe
      t.timestamps
    end
    
    create_table :cpes_cves, :id => false do |t|
      t.integer :cpe_id
      t.integer :cve_id
      t.timestamps
    end
    
    add_index :cpes_cves, [:cve_id, :cpe_id]
    add_index :cpes, :cpe
    
    execute "ALTER TABLE cpes_cves ADD CONSTRAINT cpes_cves_cpe_id FOREIGN KEY (cpe_id) REFERENCES cpes (id)"
    execute "ALTER TABLE cpes_cves ADD CONSTRAINT cpes_cves_cve_id FOREIGN KEY (cve_id) REFERENCES cves (id)"
  end

  def self.down
    execute "ALTER TABLE cpes_cves DROP FOREIGN KEY cpes_cves_cpe_id"
    execute "ALTER TABLE cpes_cves DROP FOREIGN KEY cpes_cves_cve_id"
    drop_table :cpes_cves
    drop_table :cpes
  end
end
