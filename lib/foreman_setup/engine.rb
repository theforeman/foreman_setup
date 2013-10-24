require 'foreman_setup'
require 'deface'

module ForemanSetup
  class Engine < ::Rails::Engine
    engine_name ForemanSetup::ENGINE_NAME

    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/helpers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]

    initializer "foreman_setup.load_app_instance_data" do |app|
      app.config.paths['db/migrate'] += ForemanSetup::Engine.paths['db/migrate'].existent
    end

    config.to_prepare do
      begin
        ::HomeHelper.send :include, ForemanSetup::HomeHelperExt
      rescue => e
        puts "#{ForemanSetup::ENGINE_NAME}: skipping engine hook (#{e.to_s})"
      end
    end
  end

  def table_name_prefix
    ForemanSetup::ENGINE_NAME + '_'
  end

  def self.table_name_prefix
    ForemanSetup::ENGINE_NAME + '_'
  end

  def use_relative_model_naming
    true
  end

end
