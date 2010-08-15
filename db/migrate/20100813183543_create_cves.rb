class CreateCves < ActiveRecord::Migration
  def self.up
    create_table :cves do |t|
      t.string :cve_id
      t.text :summary
      t.string :cvss
      t.string :state
      t.datetime :published_at
      t.datetime :last_changed_at
      t.timestamps
    end
    
    add_index :cves, :cve_id, :unique => true
  end

  def self.down
    drop_table :cves
  end
end
