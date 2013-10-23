require File.expand_path('../lib/foreman_setup/version', __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name = "foreman_setup"

  s.version = ForemanSetup::VERSION
  s.date = Date.today.to_s

  s.summary = "Helps set up Foreman for provisioning"
  s.description = "Plugin for Foreman that helps set up provisioning."
  s.homepage = "http://github.com/theforeman/foreman_setup"
  s.licenses = ["GPL-3"]
  s.require_paths = ["lib"]

  s.authors = ["Dominic Cleal"]
  s.email = "dcleal@redhat.com"

  s.extra_rdoc_files = [
    "CHANGES.md",
    "LICENSE",
    "README.md",
  ]
  s.files = `git ls-files`.split("\n") - Dir[".*", "Gem*", "*.gemspec"]
end
