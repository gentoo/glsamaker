class CreateCveReferences < ActiveRecord::Migration
    def self.up
      create_table :cve_references do |t|
        t.string :source
        t.string :title
        t.string :uri
        t.integer :cve_id
        t.timestamps
      end

      add_index :cve_references, :cve_id
      execute "ALTER TABLE cve_references ADD CONSTRAINT cve_references_cve_id FOREIGN KEY (cve_id) REFERENCES cves (id)"
    end

    def self.down
      execute "ALTER TABLE cve_references DROP FOREIGN KEY cve_references_cve_id"
      drop_table :cve_references
    end
end
