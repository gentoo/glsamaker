class CreatePermissionsUsers < ActiveRecord::Migration
  def self.up
    create_table :permissions_users do |t|
      t.integer :user_id
      t.integer :permission_id
      t.timestamps
    end
    
    add_index :permissions_users, [:user_id, :permission_id]
  end

  def self.down
    remove_index :permissions_users, :column => [:user_id, :permission_id]
    drop_table :permissions_users
  end
end
