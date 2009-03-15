class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.integer :user_id
      t.integer :glsa_id
      t.text :text
      t.string :type
      t.boolean :read, :default => false
      t.timestamps
    end
    
    add_index :comments, :glsa_id
  end

  def self.down
    drop_table :comments
  end
end
