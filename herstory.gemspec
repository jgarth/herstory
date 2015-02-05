# coding: utf-8
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "herstory/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "herstory"
  s.version     = Herstory::VERSION
  s.authors     = ["Joachim Garth"]
  s.email       = ["jg@crispymtn.com"]
  s.homepage    = "https://github.com/crispymtn/herstory"
  s.summary     = "Tracks changes to your AR models and their associations."
  s.description = "Tracks changes to your AR models and their associations, even works with has_many :through."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.2.0"
  s.add_development_dependency "pry-rails"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "sqlite3"
end
