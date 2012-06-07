module Users
 
  #
  # It represents the resource access control to check if a profile can
  # access a resource
  #
  # If we want to control the access to a resource we only have to include this module in the
  # resource
  #
  # It works on DataMapper and YSD Persistence
  #
  # By default a resource can be read/write by the owner, read by the group and not allowed by the others
  module ResourceAccessControl

      # When the resource is included
      #
      def self.included(model)

        model.property :owner, String, :field => 'owner', :length => 32
        model.property :group, String, :field => 'group', :length => 32
        model.property :modifiers, String, :field => 'modifiers', :length => 3, :default => 'ARN'
  
      end
  
      # Check if a profile can access to the resource
      # @param [Profile] profile
      # @param [Symbol] operation
      #  :read
      #  :write
      #
      def allowed?(profile, operation)
    
        owner = attribute_get(:owner)
        group = attribute_get(:group)
        modifiers = attribute_get(:modifiers).split('')
  
        # Check the access required
        access_required = case operation
          when :read
            :R
          when :write
            :W
        end
  
        # Extract information from the modifiers    
        owner_modifier     = modifiers.first || :N
        group_modifier     = modifiers[1] || :N
        everybody_modifier = modifiers.last || :N
  
        # Check if the profile can access the resource
        #
        #  everybody
        #  super user
        #  owner  (the profile is the user and owner_modifier allows perform it)
        #  group  (the profile belongs to the group and the group_modifier allow perform it)
        #
        everybody_modifier == access_required or profile.super_user? or (profile.username == owner and owner_modifier == access_required) or (profile.groups.split(',').index(group) and group_modifier == access_required)
  
      end
       
  end # ResourceAccessControl
end #Users