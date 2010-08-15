class CreateRevisions < ActiveRecord::Migration
  def self.up
    create_table :revisions do |t|
      t.integer :glsa_id
      t.integer :revid
      t.string :title
      t.string :access, :default => "remote"
      t.string :product
      t.string :category
      t.string :severity, :default => "normal"
      t.text :synopsis
      t.text :background
      t.text :description
      t.text :impact
      t.text :workaround
      t.text :resolution
      t.timestamps
    end
    
    add_index :revisions, :glsa_id
    add_index :revisions, :revid
    add_index :revisions, :title    
  end

  def self.down
    remove_index :revisions, :synopsis
    remove_index :revisions, :title
    remove_index :revisions, :revid
    remove_index :revisions, :glsa_id
    drop_table :revisions
  end
end
