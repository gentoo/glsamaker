class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.string :name
      t.string :title
      t.string :description
      t.timestamps
    end
    
    add_index :permissions, :name, :unique => true
  end

  def self.down
    remove_index :permissions, :column => :name
    drop_table :permissions
  end
end
