require 'data_mapper' unless defined?DataMapper
require 'ysd-md-user-profile'
require 'digest/md5' unless defined?Digest

module Users

  # Defines an exception to check when the password is not valid
  #
  class PasswordNotValid < RuntimeError; end

  # Defines an exception to check when the email does not exist
  # 
  class EmailNotExist < RuntimeError; end

  #
  # It represents a registered profile, a user who has filled the registration form
  #
  class RegisteredProfile < Profile
  	    
    property :password, String, :field => 'password', :length => 32               # The password (hashed)
    property :salt, String, :field => 'salt', :length => 5                    # Salt to check the password

    alias :base_attribute_set :attribute_set
    
    #
    # Login the user 
    #
    # @param [String] username
    # @param [String] password
    # @result [Profile] 
    #   The connected user
    #
    def self.login(username, password)

      user = RegisteredProfile.get(username)
      
      if user and user.check_password(password)
        return user
      end

      return nil

    end

    #
    # Profile signup (creates a new profile through the signup process)
    # 
    #
    def self.signup(data)
      
      profile = create_user(data) do |profile| 
                   BusinessEvents::BusinessEvent.fire_event(:profile_signup, 
                        {:username => profile.username, :password => data[:password]}) 
                end
        
    end  
    
    #
    # Creates an user account
    #
    def self.create_user(data)
      
      data.symbolize_keys!

      profile = nil

      RegisteredProfile.transaction do |transaction|
        profile = RegisteredProfile.create(data)
        yield profile if block_given?
        transaction.commit
      end

      return profile

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
      
      RegisteredProfile.transaction do |transaction|     
        
        if profile = RegisteredProfile.first({:email => email})
        
          new_password = random_string(8)     
          user.set_password(new_password)
          user.save

          BusinessEvents::BusinessEvent.fire_event(:profile_reset_password, {:username => profile.username, :password => new_password})
       
          transaction.commit

        else
          raise EmailNotExist, "The email does not exists"
        end

      end
      
    end    
    
    #
    # Change the profile password, but first it checks the password matches the current profile password
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
        save
      else
        raise PasswordNotValid, "The password is not valid"
      end
     
    end

    #
    # Assign attributes
    #  
    # @param [Hash] attributes
    #
    def attributes=(attributes)
       
      attributes.symbolize_keys!
       
      password = if attributes.has_key?(:password)
                   attributes.delete(:password)
                 end
      
      super(attributes)
      
      if password
        attribute_set(:password, password)
      end

    end
    
    #
    # Asign an attribute value
    #
    def attribute_set(name, value)  
      if (name.to_sym == :password)
        set_password(value)
      else
        super(name, value)
      end    
    end

    #
    # Make sure the property password is not serialized
    #    
    def properties_to_serialize(options={})
      super(options).select do |property|
         property.name.to_sym != :password 
      end
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
      password == Digest::MD5.hexdigest("#{salt}--#{check_this_password}")
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


  end	

end