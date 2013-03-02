require 'data_mapper' unless defined?DataMapper

module Users
  #
  # It holds the groups the user belongs to
  #	
  class ProfileGroup
     include DataMapper::Resource

    storage_names[:default] = 'userds_users_groups'  
    
    belongs_to :profile, 'Profile', :child_key => [:profile_username], :parent_key => [:username], :key => true
    belongs_to :group,   'Group',   :child_key => [:usergroup_group],  :parent_key => [:group], :key => true

    alias old_save save
    
    #
    # Saving the profile/group
    #
    def save

      if self.profile and (not self.profile.saved?)
      	self.profile = Profile.get(profile.username)
      end

      if self.group and (not self.group.saved?)
      	self.group = Group.get(group.group)
      end

      old_save

    end

  end
end