require 'spec_helper'

#
# Describing the behaviour of the registered profile class
#
describe Users::RegisteredProfile do 

  before :all do

     @user_group  = Users::Group.create({:group => 'user', :name => 'Users', :description => 'Standard users'})
     @staff_group = Users::Group.create({:group => 'staff', :name => 'Staff', :description => 'Staff users'})


     @profile = Users::RegisteredProfile.new({:username => 'admin', 
                                              :superuser => true, :password => '1234', 
                                              :full_name => 'Administrator', 
                                              :usergroups => [{:group => 'staff'},{:group => 'user'}]     
                                             })
  
     @profile_usergroups = Users::RegisteredProfile.new({:username => 'fernandez', 
                                              :superuser => true, :password => '1234', 
                                              :full_name => 'Antonio Fernandez', 
                                              :profile_groups => [:group => {:group => 'staff'}] 
                                             })

  end

  it "should create a registered user" do

    @profile.save

    @profile.errors do |e| puts "ERROR : #{e.inspect}" end

    loaded_profile = Users::Profile.get(@profile.username)

    loaded_profile.check_password('1234').should be_true
    loaded_profile.profile_groups.size.should == 2
    loaded_profile.usergroups.size.should == 2
    loaded_profile.usergroups.include?(Users::Group.get('staff')).should be_true
    loaded_profile.usergroups.include?(Users::Group.get('user')).should be_true
    loaded_profile.belongs_to?(@staff_group)

  end



end