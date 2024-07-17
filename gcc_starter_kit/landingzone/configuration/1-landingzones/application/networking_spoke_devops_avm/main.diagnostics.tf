# nsg diagnostics
module "diagnosticsetting1" {
  source  = "AcceleratorFramew0rk/aaf/azurerm//modules/diagnostics/terraform-azurerm-diagnosticsetting"

  name                = "${module.naming.monitor_diagnostic_setting.name_unique}-runner"
  target_resource_id = module.nsg1.resource.id
  log_analytics_workspace_id = local.remote.log_analytics_workspace.id
  diagnostics = {
    categories = {
      log = [
        # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
        ["NetworkSecurityGroupEvent", true, false, 7],
        ["NetworkSecurityGroupRuleCounter", true, false, 7],
      ]
      metric = [
        #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
        #["AllMetrics", true, false, 7],
      ]
    }
  }
}

