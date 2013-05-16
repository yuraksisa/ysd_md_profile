require 'data_mapper' unless defined?DataMapper
require 'ysd_md_comparison' unless defined?Conditions::Comparison
require 'ysd-md-business_events' unless defined?BusinessEvents::BusinessEvent
require 'ysd-plugins' unless defined?Plugins::ApplicableModelAspect
require 'ysd_md_variable'
require 'ysd_dm_finder'
require 'ysd-md-user-group'

module Users

  #
  # This is the base class of all user profiles
  #
  class Profile
    include DataMapper::Resource
    extend  Plugins::ApplicableModelAspect         # Extends the entity to allow apply aspects
    extend  Yito::Model::Finder
    
    storage_names[:default] = 'userds_users'      

    property :username, String, :field => 'username', :length => 20, :key => true             # The username
    property :email, String, :field => 'email', :length => 50, :unique_index => :profile_mail # The user email
  
    property :full_name, String, :field => 'full_name', :length => 60                  # Full name 
    property :date_of_birth, DateTime, :field => 'date_of_birth'                       # Date of birth
    property :country_of_origin, String, :field => 'country_of_origin', :length => 80  # Country of origin
    property :sex, String, :field => 'sex', :length => 1                               # Sex (0-male, 1-female)
    property :about_me, Text, :field => 'about_me'                                     # About me (information)
  
    property :preferred_language, String, :field => 'preferred_language', :length => 2 # Preferred language

    property :creation_date, DateTime      # Creation date (auditory information)
    property :last_access, DateTime        # The last access to the system
    
    property :superuser, Boolean, :field => 'superuser', :default => false             # It's a superuser

    has n, :profile_groups, 'ProfileGroup', :child_key => [:profile_username], :parent_key => [:username], :constraint => :destroy
    has n, :usergroups, 'Group', :through => :profile_groups, :via => :group

    property :type, Discriminator        # The profile type
    
    #
    # Override the save method to be sure the user and its groups are saved in a transaction
    #    
    def save

      transaction do |t|
        check_usergroups! if self.usergroups and (not self.usergroups.empty?)
        super
        t.commit
      end

    end

    before :create do 

      self.creation_date = Time.now
        if usergroups.empty?
          SystemConfiguration::Variable.get_value('profile.default_group', 'user').split(",").each do |group|
             if ug = Group.get(group)
               usergroups << ug
             end
          end
      end

    end

    # ================= Class methods ====================
        
    #
    # Find profiles excluding the username passed as argument
    #
    # @param [String] the username which has to be excluded
    # @param [Numeric] limit
    # @param [Numeric] offset
    #
    # @return [Array] 
    #
    #   The first element is the profile subset limited by limit, offset
    #   The second element is the total number of profiles which matches
    #
    def self.find_other_profiles(connected_username, limit, offset)
         
        result = [] 
         
        result << Users::Profile.all(:conditions => {:username.not => [connected_username,'admin'] }, 
                                     :order=>[:photo_path.desc], 
                                     :limit => limit , 
                                     :offset => offset)    
    
        result << Users::Profile.count(:conditions => {:username.not => [connected_username,'admin']})

        result
    
    end
     
    #
    # Updates the last access
    # 
    def update_last_access

       last_access = Time.now
       save

    end

    #
    # Calculates the age
    #
    # It expects that exists date_of_birth metadata
    #
    def age
     
      age = nil    
     
      if _date_of_birth=attribute_get(:date_of_birth) 
        
        if _date_of_birth.to_s.strip.length > 0

          if _date_of_birth.is_a?(String)
            _date_of_birth = Time.parse(_date_of_birth)
          else
            if _date_of_birth.is_a?(DateTime)
              _date_of_birth = date_of_birth.to_time
            end
          end

          base  = Time.utc(1970,1,1)
          today = Time.now.utc
          
          if _date_of_birth.to_time >= base
            age = Time.at(today-_date_of_birth).year-1970
          else   
            before_t = Time.at(base-_date_of_birth)
            after_t  = Time.at(today-_date_of_birth)
            plus_1 = (_date_of_birth.month < today.month or (_date_of_birth.month == today.month and _date_of_birth.day <= today.day))?1:0 
            age = (before_t.year - 1970) + (after_t.year - 1970) + plus_1 
          end   
          
        end

      end
 
      return age
   
    end
    
    #
    # Checks if the user is a superuser
    #
    def is_superuser?
    
      superuser == true
    
    end

    #
    # Check if the user belongs to the group(s)
    #
    # @param[String] usergroup to check if the user belongs to
    # @return [Boolean] true if the user belongs to the usergroup
    #
    def belongs_to?(usergroup)

      if usergroup.is_a?Array
        not (usergroup & (usergroups.map{|group| group.group})).empty?
      else
        usergroups.map{|group| group.group}.include?(usergroup)
      end

    end
  
    #
    # Exporting the profile
    #  
    def as_json(options={})

      methods = options[:methods] || []
      methods << :age

      relationships = options[:relationships] || {}
      relationships.store(:usergroups, {})

      super(options.merge(:methods => methods, :relationships => relationships))

    end
  
    # Check if the email is registered in the system
    #
    # @param [String] email
    #   The user email
    #
    # @return [Boolean]
    #   If the mail is registered or not in the system
    #
    #
    def self.email_registered?(email)
      
      Users::Profile.count(:email => email) > 0

    end  

    # ============ Resource info interface =================
     
    #
    # Get the resource information
    # 
    def resource_info

      "profile_#{key}"

    end

    def self.ANONYMOUS_USER
     
      Users::Profile.new({:username => 'anonymous', :superuser => false, :full_name=> 'Anonymous', 
                          :usergroups => [Users::Group.new({:group => 'anonymous'})]
                          })
   
    end

    private
    
    #
    # Check the user groups
    #
    def check_usergroups!

      self.usergroups.map! do |ug|
        if (not ug.saved?) and loaded_usergroup = Users::Group.get(ug.group)
          loaded_usergroup
        else
          ug
        end 
      end

    end

  end # Profile   
  
end # Users