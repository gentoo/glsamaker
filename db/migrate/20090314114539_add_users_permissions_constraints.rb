class AddUsersPermissionsConstraints < ActiveRecord::Migration  
  def self.up
    execute "ALTER TABLE permissions_users ADD CONSTRAINT permissions_users_users FOREIGN KEY (user_id) REFERENCES users (id)"
    execute "ALTER TABLE permissions_users ADD CONSTRAINT permissions_users_permissions FOREIGN KEY (permission_id) REFERENCES permissions (id)"
  end

  def self.down
    execute "ALTER TABLE permissions_users DROP FOREIGN KEY permissions_users_users"
    execute "ALTER TABLE permissions_users DROP FOREIGN KEY permissions_users_permissions"
  end
end
