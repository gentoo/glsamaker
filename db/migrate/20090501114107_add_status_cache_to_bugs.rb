class AddStatusCacheToBugs < ActiveRecord::Migration
  def self.up
    add_column :bugs, :whiteboard, :string
    add_column :bugs, :arches, :string
  end

  def self.down
    remove_column :bugs, :arches
    remove_column :bugs, :whiteboard
  end
end
