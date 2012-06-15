module Users
 
  #
  # It represents the resource access control to check if a profile can access a resource
  #
  # If we want to control the access to a resource we only have to include this module in the
  # resource
  #
  # It works on DataMapper and YSDPersistence
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

      #
      # When the resource is included
      #
      def self.included(model)

        model.property :permission_owner, String, :field => 'permission_owner', :length => 32
        model.property :permission_group, String, :field => 'permission_group', :length => 32
        model.property :permission_modifier_owner, Integer, :field => 'permission_modifier_owner', :default => 6
        model.property :permission_modifier_group, Integer, :field => 'permission_modifier_group', :default => 2
        model.property :permission_modifier_all, Integer, :field => 'permission_modifier_all', :default => 0
  
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
  
      
      #
      # Create the query conditions to access the resource
      #
      # @params [Profile]
      #
      #  the user profile we can check
      #
      # @return [Array]
      #
      #  Array which contains the set of OR conditions which have to be matched to access the resource
      #
      #
      def query_conditions(profile)
      
        conditions = []
      
        if profile
       
          conditions_owner = {}      
          conditions_owner.store(:permission_owner => profile)
          conditions_owner.store(:permission_modifier_owner => [2,6])
          
          conditions << conditions_owner        
       
          conditions_group = {}        
          conditions_group.store(:permission_group => profile.groups.split(','))
          conditions_group.store(:permission_modifier_group => [2,6])
     
          conditions << conditions_group
        
        end
        
        conditions_all = {}        
        conditions_all.store(:permission_modifier_all => [2,6])
        conditions << conditions_all
        
        conditions 
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
           can_access = (options.include(attribute_get(:permission_modifier_group)) and profile.groups.split(',').include(permission_group)) or
                        (options.include(attribute_get(:permission_modifier_owner)) and profile == attribute_get(:permission_owner))
        end
        
        can_access
            
      end
      
       
  end # ResourceAccessControl
end #Users