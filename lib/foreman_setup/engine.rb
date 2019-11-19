require 'foreman_setup'

module ForemanSetup
  class Engine < ::Rails::Engine
    engine_name 'foreman_setup'

    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/helpers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]

    initializer "foreman_setup.load_app_instance_data" do |app|
      ForemanSetup::Engine.paths['db/migrate'].existent.each do |path|
        app.config.paths['db/migrate'] << path
      end
    end

    initializer 'foreman_setup.register_plugin', :before => :finisher_hook do |app|
      Foreman::Plugin.register :foreman_setup do
        requires_foreman '>= 1.22.0'

        menu :top_menu, :provisioners, :url_hash => {:controller=> :'foreman_setup/provisioners', :action=>:index},
                 :caption=> N_('Provisioning setup'),
                 :parent => :infrastructure_menu,
                 :first => true

        security_block :provisioning do
          permission :edit_provisioning, {:'foreman_setup/provisioners' => [:index, :new, :update, :create, :show, :destroy, :step1,
             :step2, :step2_update, :step3, :step4, :step4_update, :step5] }, :resource_type => "ForemanSetup::Provisioner"
        end
        role "Provisioning setup", [:edit_provisioning]
      end
    end

    initializer 'foreman_setup.register_gettext', :after => :load_config_initializers do |app|
      locale_dir = File.join(File.expand_path('../../..', __FILE__), 'locale')
      locale_domain = 'foreman_setup'
      Foreman::Gettext::Support.add_text_domain locale_domain, locale_dir
    end
  end

  def table_name_prefix
    'setup_'
  end

  def self.table_name_prefix
    'setup_'
  end

  def use_relative_model_naming
    true
  end

end
