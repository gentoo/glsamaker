class CreateBugs < ActiveRecord::Migration
  def self.up
    create_table :bugs do |t|
      t.integer :bug_id
      t.text :title
      t.integer :revision_id
      t.timestamps
    end
    
    add_index :bugs, :revision_id
  end

  def self.down
    drop_table :bugs
  end
end
