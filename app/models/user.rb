class User < ActiveRecord::Base
  has_and_belongs_to_many :permissions
  
  validates_uniqueness_of :login, :message => "User name must be unique"
  validates_presence_of :login, :message => "User name can't be blank"
  
  validates_format_of :email, :with => /[\w.%+-]+?@[\w.-]+?\.\w{2,6}$/, :message => "Invalid Email address format"
  
  # Returns if the user has the permission to do the action with the name +perm+
  def has_permission_for?(perm)
    p = Permission.find(:first, :conditions => ['name = ?', perm])
    raise(ArgumentError, "Permission not found") if p == nil
    
    self.permissions.include?(p)
  end
  
  # Grants the user permission to do +perm+
  def grant_permission_for(perm)
    return false if has_permission_for?(perm)
    
    p = Permission.find(:first, :conditions => ['name = ?', perm])
    raise(ArgumentError, "Permission not found") if p == nil
    
    pu = PermissionsUsers.new
    pu.permission_id = p.id
    pu.user_id = self.id
    pu.save!
  end
  
  # Revokes the user's permission to do +perm+
  def revoke_permission_for(perm)
    return false unless has_permission_for?(perm)
    
    self.permissions.find(:first, :conditions => ['name = ?', perm]).delete
  end
end
