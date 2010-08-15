class CreatePackages < ActiveRecord::Migration
  def self.up
    create_table :packages do |t|
      t.integer :revision_id
      t.string :my_type
      t.string :atom
      t.string :version
      t.string :comp
      t.string :arch
      t.boolean :automatic, :default => true
      t.timestamps
    end

    add_index :packages, :revision_id
  end

  def self.down
    remove_index :packages, :column => :revision_id
    drop_table :packages
  end
end
