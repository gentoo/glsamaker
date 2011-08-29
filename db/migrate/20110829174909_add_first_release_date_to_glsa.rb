class AddFirstReleaseDateToGlsa < ActiveRecord::Migration
  def change
    add_column :glsas, :first_released_at, :datetime
  end
end
