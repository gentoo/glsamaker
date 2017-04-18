class AddSlotsToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :slot, :string
    Package.find_each do |package|
      if package.slot.nil?
        package.slot = '*'
        package.save!
      end
    end
  end
end
