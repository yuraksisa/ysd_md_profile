require 'data_mapper' unless defined?DataMapper

module Users
  
  #
  # It represents the profile groups
  #
  class UserGroup 
    include DataMapper::Resource
    
    storage_names[:default] = 'userds_groups'
    
    property :group, String, :field => 'group', :length => 32, :key => true
    property :name, String,  :field => 'name', :length => 80
    property :description, String, :field => 'description', :length => 256
    
  end

end