require 'foreman_setup/version'

module ForemanSetup
  ENGINE_NAME = 'setup'

  require 'foreman_setup/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
end
