class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :login
      t.string :name
      t.string :email
      t.boolean :disabled, :default => false
      t.text :preferences
      t.timestamps
    end
    
    add_index :users, :login, :unique => true
  end

  def self.down
    remove_index :users, :column => :login
    drop_table :users
  end
end
