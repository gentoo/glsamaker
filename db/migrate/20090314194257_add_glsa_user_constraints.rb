class AddGlsaUserConstraints < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE glsas ADD CONSTRAINT glsas_users_requesters FOREIGN KEY (requester) REFERENCES users (id)"
    execute "ALTER TABLE glsas ADD CONSTRAINT glsas_users_submitters FOREIGN KEY (submitter) REFERENCES users (id)"
    execute "ALTER TABLE glsas ADD CONSTRAINT glsas_users_bugreadymakers FOREIGN KEY (bugreadymaker) REFERENCES users (id)"
  end

  def self.down
    execute "ALTER TABLE glsas DROP FOREIGN KEY glsas_users_requesters"
    execute "ALTER TABLE glsas DROP FOREIGN KEY glsas_users_submitters"
    execute "ALTER TABLE glsas DROP FOREIGN KEY glsas_users_bugreadymakers"    
  end
end
