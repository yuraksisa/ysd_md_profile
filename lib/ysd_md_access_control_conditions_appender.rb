require 'ysd_md_system' unless defined?Model::System::Request
require 'ysd_md_comparison' unless defined?Conditions::Comparison

module Users

  # AccessControlConditionsAppender
  #
  # It's an extension which builds the conditions that will allow retrieve only the
  # information which belongs to us or which we have access to.
  #
  # It includes the YSD::System::Request module to access request information
  #
  # Not use this module directly. Use your concrete ORM implementation
  #
  module AccessControlConditionsAppender
      include Model::System::Request
                
        #
        # Create the query conditions to access the resource
        #
        # @params [Profile]
        #
        #  the user profile we can check
        #
        # @return [Conditions::Comparison]
        #
        #  A Comparison which have to be matched to access the resource
        #
        #
        def access_control_conditions
      
          conditions = []
      
          profile = connected_user
      
          if profile
       
            conditions_owner = Conditions::JoinComparison.new('$and', 
                                 [Conditions::Comparison.new(:permission_owner, '$eq', profile.username),
                                  Conditions::Comparison.new(:permision_modifier_owner, '$in', [2,6])])
          
            conditions << conditions_owner        
       
            if (profile_groups=profile.usergroups).length > 0
       
              conditions_group = Conditions::JoinComparison.new('$and',
                                   [Conditions::Comparison.new(:permission_group, '$in', profile_groups),
                                    Conditions::Comparison.new(:permission_modifier_group, '$in', [2,6])])    
            
              conditions << conditions_group
            end
        
          end
        
          conditions_all = Conditions::Comparison.new(:permission_modifier_all, '$in', [2,6])       
          conditions << conditions_all


          if conditions.length > 1
            conditions = Conditions::JoinComparison.new('$or', conditions)
          else        
            conditions.first
          end
          
        end
        
                  
   end

   #
   # Conditions for DataMapper::Resource
   #
   # It's a module which can be extended by a datamapper resource to "inject"
   # the conditions to access only those resource which we have access
   #
   module AccessControlConditionsAppenderDataMapper
         include AccessControlConditionsAppender

        #
        # Override the method to append the conditions
        #
        def all(options = {})
                   
          original_all(options)                  

        end
      
   end

   #
   # Conditions for a Persistence::Resource
   #
   # It's a module which can be extended by a datamapper resource to "inject"
   # the conditions to access only those resource which we have access   
   #  
   module AccessControlConditionsAppenderPersistence
         include AccessControlConditionsAppender
         
        #
        # Override the method to append the conditions
        #
        def all(options = {})

          upgraded_options = build_access_control_conditions(options)
          original_all(upgraded_options)                  

        end         
         
        def count(options = {})
        
          upgraded_options = build_access_control_conditions(options)
          count = original_count(upgraded_options)
        
          count
          
        end
        
        private
        
        def build_access_control_conditions(options)
        
          # Get the access control conditions
          ac_conditions = access_control_conditions
          
          # Merge with the conditions
          
          conditions = if options.has_key?(:conditions)
                          Conditions::JoinComparison.new('$and', [options.fetch(:conditions), ac_conditions])
                       else
                          ac_conditions
                       end
 
          # Prepare the query
       
          upgraded_options = options.dup
          upgraded_options.store(:conditions, conditions)
        
          upgraded_options
          
        end 
         
   end
end