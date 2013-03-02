module Users
  #
  # It holds information about the connected user in the process
  #
  module ConnectedUser
    
    #
    # Get the connected user 
    #
    # @return [Users::Profile]
    def connected_user
     Thread.current[:connected_user] || Users::Profile.ANONYMOUS_USER
    end

  end
end