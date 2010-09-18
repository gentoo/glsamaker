class AddSystemUser < ActiveRecord::Migration
  def self.up
    execute "INSERT INTO users (id, login, name, email, access, disabled, jefe) VALUES" + 
    "(1, 'system', 'Sytem Account', 'glsamaker@gentoo.org', 0, 0, 0)"
    execute "UPDATE users SET id = 0 WHERE id = 1"
    execute "ALTER TABLE users AUTO_INCREMENT = 1"
  end

  def self.down
    execute "DELETE FROM users WHERE id = 0"
  end
end
