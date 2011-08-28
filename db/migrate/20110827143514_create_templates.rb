class CreateTemplates < ActiveRecord::Migration
  def change
    create_table :templates do |t|
      t.string :name
      t.text :text
      t.string :target
      t.boolean :enabled, :default => true

      t.timestamps
    end
  end
end
