require 'data_mapper' unless defined?DataMapper

module Users
  
  #
  # It represents a group of users.
  #
  # A group is a way to organize users. The users can belong to some groups and this will
  # help to define which actions can a user done.
  #
  class Group 
    include DataMapper::Resource
    
    storage_names[:default] = 'userds_groups'
    
    property :group, String, :field => 'group', :length => 32, :key => true
    property :name, String,  :field => 'name', :length => 80
    property :description, String, :field => 'description', :length => 256
    
  end

end