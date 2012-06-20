module Users
 
  #
  # It represents the resource access control to check if a profile can access a resource
  #
  # If we want to control the access to a resource we only have to include this module in the
  # resource
  #
  # By default a resource can be read/write by the owner, read by the group and not allowed by the others
  #
  # We have created three properties to represents each of the permission modifiers to make the query process easy
  #
  #                    User   -     Group    -    All
  #  
  #                    W R X        W R X        W R X 
  #                    -----        -----        -----
  #   No permission    0 0 0        0 0 0        0 0 0
  #   Read             0 1 0        0 1 0        0 1 0
  #   Write            1 0 0        0 1 0        0 1 0
  #   Read and Write   1 1 0        0 1 0        0 1 0
  #
  #
  #
  module ResourceAccessControl
         
      def self.prepare_model(model)

        model.property :permission_owner, String, :field => 'permission_owner', :length => 32
        model.property :permission_group, String, :field => 'permission_group', :length => 32
        model.property :permission_modifier_owner, Integer, :field => 'permission_modifier_owner', :default => 6
        model.property :permission_modifier_group, Integer, :field => 'permission_modifier_group', :default => 2
        model.property :permission_modifier_all, Integer, :field => 'permission_modifier_all', :default => 0
         
        model.class_eval do
          class << self 
             alias_method :original_all, :all
          end
        end         
         
      end
  
      #
      # Check if the profile can read the resource
      #
      # @params [Users::Profile]
      #
      #  The user profile (or nil for anonymous user)
      #
      def can_read?(profile)
      
        can_access?(profile, [2,6])
        
      end
 
      #
      # Check if the profile can write the resource
      #
      # @params [Users::Profile]
      #
      #  The user profile (or nil for anonymous user)
      #     
      def can_write?(profile)
      
        can_access?(profile, [4,6])
      
      end
              
      private
      
      #
      # Check if the user can access the resource 
      #
      # @param [Users::Profile] profile
      #   
      #   The user profile
      #
      # @param [Array] options
      #
      #   Array which represents the modifiers
      #
      # @return [Boolean]
      #
      #   True if the profile can access the resource
      #
      #
      def can_access?(profile, options)
      
        can_access = options.include(attribute_get(:permission_modifier_all)) 
        
        if profile and not can_access
           can_access = (options.include(attribute_get(:permission_modifier_group)) and profile.usergroups.index(permission_group)) or
                        (options.include(attribute_get(:permission_modifier_owner)) and profile == attribute_get(:permission_owner))
        end
        
        can_access
            
      end
       
  end # ResourceAccessControl

  #
  # ResourceAccessControl for DataMapper
  #
  module ResourceAccessControlDataMapper
    include ResourceAccessControl
    
      #
      # When the resource is included
      #
      def self.included(model)    
     
        ResourceAccessControl.prepare_model(model)
        model.extend(AccessControlConditionsAppenderDataMapper)  
     
     end
           
  end # ResourceAccessControlDataMapper
  
  
  #
  # ResourceAccessControl for Persistence System
  #
  module ResourceAccessControlPersistence
    include ResourceAccessControl
    
      #
      # When the resource is included
      #
      def self.included(model)    
        
        ResourceAccessControl.prepare_model(model) 
        model.extend(AccessControlConditionsAppenderPersistence)   
     
     end    
    
     #
     # Updates the resource access control information if not has been set
     #
     def create
     
      profile = connected_user
      
      if connected_user and (attribute_get(:permission_owner).nil? or attribute_get(:permission_owner).to_s.strip.length == 0)
        attribute_set(:permission_owner, connected_user.username) 
      end

      if connected_user and connected_user.usergroups.length > 0 and (attribute_get(:permission_group).nil? or attribute_get(:permission_group).to_s.strip.length == 0)
        attribute_set(:permission_group, connected_user.usergroups.first) 
      end

      if attribute_get(:permission_modifier_owner).nil? or attribute_get(:permission_modifier_owner).to_s.strip.length == 0      
        attribute_set(:permission_modifier_owner, 6) 
      end
      
      if attribute_get(:permission_modifier_group).nil? or attribute_get(:permission_modifier_group).to_s.strip.length == 0
        attribute_set(:permission_modifier_group, 2) 
      end
      
      if attribute_get(:permission_modifier_all).nil? or attribute_get(:permission_modifier_all).to_s.strip.length == 0
        attribute_set(:permission_modifier_all, 2) 
      end
      
      super
     
     end
     
    
        
  end # ResourceAccessControlPersitence

  
end #Users