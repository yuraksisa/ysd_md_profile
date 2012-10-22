require 'ysd-persistence' if not defined?Persistence
require 'digest/md5' unless defined?Digest
require 'ysd_md_comparison' unless defined?Conditions::Comparison
require 'ysd-md-business_events' unless defined?BusinessEvents::BusinessEvent
require 'ysd_core_plugins' unless defined?Plugins::ApplicableModelAspect

module Users

  # Defines an exception to check when the password is not valid
  #
  class PasswordNotValid < RuntimeError; end

  # Defines an exception to check when the email does not exist
  # 
  class EmailNotExist < RuntimeError; end

  #
  # This represents a user profile  
  #
  #
  class Profile
    include Persistence::Resource
    include Plugins::ApplicableModelAspect         # Extends the entity to allow apply aspects
  
    alias :base_attribute_set :attribute_set
  
    # Defines the Profile properties
  
    property :username, String             # The username
    property :password, String             # The password (hashed)
    property :salt, Object                 # Salt to check the password
    property :email, String                # The user email
  
    property :full_name, String            # Full name 
    property :date_of_birth, DateTime      # Date of birth
    property :country_of_origin, String    # Country of origin
  
    property :preferred_language, String   # Preferred language
    property :creation_date, DateTime      # Creation date (auditory information)
    property :last_access, DateTime        # The last access to the system
    
    property :superuser, Object            # It's a superuser
    property :usergroups, Object           # An array with the list of the group which he/she belongs to
        
    # ================= Class methods ====================
    
    #
    # Finds all profiles
    #
    def self.find_all(count=true)
    
      result = []
    
      result << Users::Profile.all
      
      if count
        result << Users::Profile.count
      end
      
      if result.length == 1
        result = result.first
      end
      
      result
    
    end
    
    #
    # Find profiles excluding us
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
    def self.find_other_profiles(username, limit, offset)
    
        # Query for the profiles
        conditions = Conditions::Comparison.new(:username, '$ne', username)
         
        result = [] 
         
        result << Users::Profile.all(:conditions => conditions, 
                                     :order=>[['photo.path',:desc]], 
                                     :limit => limit , 
                                     :offset => offset)    
    
        result << Users::Profile.count(:conditions => conditions)

        result
    
    end
    
    #
    # Login the user 
    #
    # @param [String] username
    # @param [String] password
    # @result [Profile] 
    #   The connected user
    #
    def self.login(username, password)
      user = get(username)
      
      # checks the password
      if user
        user = user.check_password(password)?user:nil
      end
      
      # update the last access 
      if user
        user.attribute_set(:last_access, Time.now)
        user.update
      end
      user
    end

    #
    # Profile signup (creates a new profile through the signup process)
    # 
    #
    def self.signup(data)
  
      user_password = data['password']
      data['superuser'] = false if not data['superuser']
    
      # Create the profile
      profile = Profile.new(data['username'], data)
      profile.create
    
      # Notifies that the profile has been created
      if defined?BusinessEvents
        BusinessEvents::BusinessEvent.fire_event(:profile_signup, {:username => profile.username, :password => user_password})
      end
    
      # Returns the profile
      profile
  
    end  
    
    # Resets the user password
    #  
    # @param [String] email
    #   The user email
    #
    # @throw EmailNotExist
    #   If it doesn't exist a profile with this email
    #    
    def self.reset_password!(email)
     
      profile = Profile.all({:conditions => Conditions::Comparison.new(:email, '$eq', email)}).first
     
      if (profile)
  
        new_password = random_string(8)     
        profile.set_password(new_password)
        profile.update
     
        # Notifies that the password has been reset
        if defined?BusinessEvents
          BusinessEvents::BusinessEvent.fire_event(:profile_reset_password, {:username => profile.username, :password => new_password})
        end
       
      else
        raise EmailNotExist, "The email does not exists"
      end
      
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
    
      Users::Profile.all(:fields=>[:email], :conditions=> Conditions::Comparison.new(:email, '$eq', email), :limit => 1).length>0
     
    end

    # =================================================

    # Overwritten to hash the password
    #
    def initialize(path, metadata={})
      super(path, metadata)    
      if (attribute_get(:password))
        set_password(attribute_get(:password))
      end    
    end
  
    # Overwritten to hash the password 
    #
    def attribute_set(name, value)  
      if (name.to_sym == :password)
        set_password(value)
      else
        super(name, value)
      end    
    end
  
    # Overwritten to store auditory data
    #
    def create
      attribute_set(:creation_date, Time.now)
      super
    end 
          
    #
    # Calculates the age
    #
    # It expects that exists date_of_birth metadata
    #
    def age
     
      age = nil    
     
      if date_of_birth=attribute_get(:date_of_birth) 
     
        if date_of_birth.strip.length > 0
     
          base  = Time.utc(1970,1,1)
          date  = Time.parse(date_of_birth) 
          today = Time.now.utc
          
          if date >= base
            age = Time.at(today-date).year-1970
          else   
            before_t = Time.at(base-date)
            after_t  = Time.at(today-base)
            plus_1 = (date.month < today.month or (date.month == today.month and date.day <= today.day))?1:0 
            age = (before_t.year - 1970) + (after_t.year - 1970) + plus_1 
          end   
       
        end
            
      end
 
      age
   
    end
    
    #
    # Checks if the user is a superuser
    #
    def is_superuser?
    
      attribute_get('superuser') || false
    
    end
    
    #
    # Gets the usergroups (make sure return array)
    #
    def usergroups
    
      value = attribute_get(:usergroups)
      
      if not value.kind_of?(Array)
        value = []
      end
      
      value
   
    end
    
    # Serializes the object to json
    # Avoid sending the password and some problematic information
    # 
    def to_json(options={})
 
      remove_attributes = [:password] 
      data = attributes.reject do |key, value| remove_attributes.index(key) end
      data.store(:age, age)
      data.store(:usergroups, usergroups)
    
      data.to_json
  
    end 
  
    # Check if the password matches the user password
    # 
    # @param [String] check_this_password
    #    The password to validate
    #
    # @return [Boolean]
    #    True if the password is right
    #
    def check_password(check_this_password)
      salt = attribute_get(:salt)
      attribute_get(:password) == Digest::MD5.hexdigest("#{salt}--#{check_this_password}")
    end
   
    # Change the password, but first it checks the password matches the current profile password
    #
    # @param [String] password
    #    The current password
    # @param [String] new_password
    #    The new password
    # 
    # @raise [PasswordNotValid] 
    #    If the password does not match the user password
    #
    def change_password!(password, new_password) 
    
      if (check_password(password)) 
        set_password(new_password)
        update
      else
        raise PasswordNotValid, "The password is not valid"
      end
     
    end
  
    # Sets the password
    #
    # @param [String] password
    #    The user password
    #
    def set_password(password)
      salt, hash_password = hash_password(password)    
      base_attribute_set(:password, hash_password)
      attribute_set(:salt, salt) 
    end
   
    private
  
    # Hash the user password 
    #
    # @param [String] password
    #  the password to hash
    #
    # @returns [Array] salt, password
    #  An array of two elements, the salt and the password
    #
    def hash_password(password) 
  
      # Generates a salt and calculates the hash
      salt = self.class.random_string(5)
      enc_password = Digest::MD5.hexdigest("#{salt}--#{password}")
  
      [salt, enc_password]
  
    end
 
    # Generates a random string of the requested size
    #
    # @param [Size] Integer
    #   The string lenght
    #
    def self.random_string(size)

      o=('a'..'z').to_a + ('A'..'Z').to_a
      (1..size).map do o[rand(o.length)] end.join

 
    end
   
  end # Profile   
end # Users