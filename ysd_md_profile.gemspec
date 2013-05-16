Gem::Specification.new do |s|
  s.name    = "ysd_md_profile"
  s.version = "0.2.27"
  s.authors = ["Yurak Sisa Dream"]
  s.date    = "2012-01-09"
  s.email   = ["yurak.sisa.dream@gmail.com"]
  s.files   = Dir['lib/**/*.rb']
  s.summary = "A model for user/profile management"
  s.homepage = "http://github.com/yuraksisa/ysd_md_profile"
    
  s.add_runtime_dependency "data_mapper","1.2.0"  # Users::Group ORM
  
  s.add_runtime_dependency "ysd-persistence"        # Users::Profile ORM
  s.add_runtime_dependency "ysd_md_business_events" # Business events   
  s.add_runtime_dependency "ysd_md_comparison"      # To build the conditions
  s.add_runtime_dependency "ysd_core_plugins"       # Aspects
  s.add_runtime_dependency "ysd_md_configuration"   # Configuration
  s.add_runtime_dependency "ysd_md_yito"            # Yito BASE

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "dm-sqlite-adapter" # Model testing using sqlite
     
end