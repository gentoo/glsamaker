class CreateReferences < ActiveRecord::Migration
  def self.up
    create_table :references do |t|
      t.integer :revision_id
      t.text :title
      t.text :url
      t.string :type
      t.timestamps
    end
    
    add_index :references, :revision_id
  end

  def self.down
    remove_index :references, :revision_id
    drop_table :references
  end
end
