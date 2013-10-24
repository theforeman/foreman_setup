module ForemanSetup
  module HomeHelperExt
    extend ActiveSupport::Concern

    included do
      alias_method_chain :settings_menu_items, :provisioners_link
    end

    def settings_menu_items_with_provisioners_link
      menu_items = settings_menu_items_without_provisioners_link
      menu_items[2][2].insert(7, [_('Provisioning Setup'), :'foreman_setup/provisioners']) if menu_items[2]
      menu_items
    end
  end
end
