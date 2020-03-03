module ForemanSetup
  module ProvisionerHelper
    def provisioner_wizard(step)
      wizard_header(
        step,
        _("Pre-requisites"),
        _("Network config"),
        _("Foreman installer"),
        _("Installation media"),
        _("Completion")
      )
    end
  end
end
