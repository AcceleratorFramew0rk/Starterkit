resource "azurerm_resource_group" "this" {
  name     = "${module.naming.resource_group.name}-solution-accelerators-management-bastionhost" 
  location = "${try(local.global_settings.location, var.location)}" 
}


