class CreateGlsas < ActiveRecord::Migration
  def self.up
    create_table :glsas do |t|
      t.string :glsa_id
      t.integer :requester
      t.integer :submitter
      t.integer :bugreadymaker
      t.string :status
      t.boolean :restricted, :default => false
      t.timestamps
    end
    
    add_index :glsas, :glsa_id, :unique => true
    add_index :glsas, :status
  end

  def self.down
    remove_index :glsas, :status
    remove_index :glsas, :glsa_id
    drop_table :glsas
  end
end
