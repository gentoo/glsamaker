class CreateBugs < ActiveRecord::Migration
  def self.up
    create_table :bugs do |t|
      t.integer :bug_id
      t.text :title
      t.integer :revision_id
      t.timestamps
    end

    add_index :bugs, :revision_id
    add_index :bugs, :bug_id
  end

  def self.down
    remove_index :bugs, :column => :revision_id
    remove_index :bugs, :column => :bug_id
    drop_table :bugs
  end
end
