require 'foreman_setup/version'

module ForemanSetup
  require 'foreman_setup/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
end
