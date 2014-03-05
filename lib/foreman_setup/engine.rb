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

    initializer 'foreman_setup.register_plugin', :after=> :finisher_hook do |app|
      Foreman::Plugin.register :foreman_setup do
        requires_foreman '> 1.4'

        menu :top_menu, :provisioners, :url_hash => {:controller=> :'foreman_setup/provisioners', :action=>:index},
                 :caption=> N_('Provisioning setup'),
                 :parent => :infrastructure_menu,
                 :first => true

        security_block :provisioning do
          permission :edit_provisioning, {:'foreman_setup/provisioners' => [:index, :new, :update, :create, :show, :destroy, :step1,
             :step2, :step2_update, :step3, :step4, :step4_update, :step5] }, :resource_type => "ForemanSetup::Provisioner"
        end
        role "Provisioning setup", [:edit_provisioning]
      end if defined? Foreman::Plugin
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
