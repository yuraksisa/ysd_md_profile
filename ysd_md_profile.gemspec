Gem::Specification.new do |s|
  s.name    = "ysd_md_profile"
  s.version = "0.1"
  s.authors = ["Yurak Sisa Dream"]
  s.date    = "2012-01-09"
  s.email   = ["yurak.sisa.dream@gmail.com"]
  s.files   = Dir['lib/**/*.rb']
  s.summary = "A model for user/profile management"
  
  s.add_runtime_dependency "data_mapper","1.1.0"  # Users::Group ORM
  
  s.add_runtime_dependency "ysd-persistence"        # Users::Profile ORM
  s.add_runtime_dependency "ysd_md_business_events" # Business events   
  s.add_runtime_dependency "ysd_md_system"          # YSD::System::Request
   
end