# module "virtual_subnet1" {
#   source = "AcceleratorFramew0rk/aaf/azurerm//modules/networking/terraform-azurerm-subnet"

#   virtual_network_name  = local.remote.networking.virtual_networks.hub_intranet_egress.virtual_network.name 
#   resource_group_name   = local.remote.resource_group.name # resource group name of the virtual network
#   subnets = local.global_settings.subnets.hub_intranet_egress
# }
module "virtual_subnet1" {
  # source = "./modules/subnet"
  source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"
  version = "0.2.3"

  for_each = try(var.subnets.hub_intranet_egress, null) == null ? local.global_settings.subnets.hub_intranet_egress : var.subnets.hub_intranet_egress

  virtual_network                               = { resource_id = local.remote.networking.virtual_networks.hub_intranet_egress.virtual_network.id }
  name                                          = each.value.name
  address_prefixes                              = each.value.address_prefixes
  delegation                                    = try(each.value.delegations, null)
  # default_outbound_access_enabled               = try(each.value.default_outbound_access_enabled, null)
  # nat_gateway                                   = try(each.value.nat_gateway, null)
  # network_security_group                        = try(each.value.network_security_group, null)
  # private_endpoint_network_policies             = try(each.value.private_endpoint_network_policies, null)
  # private_link_service_network_policies_enabled = try(each.value.private_link_service_network_policies_enabled, null)
  # route_table                                   = try(each.value.route_table, null)
  # service_endpoints                             = try(each.value.service_endpoints, null)
  # service_endpoint_policies                     = try(each.value.service_endpoint_policies, null)
  # role_assignments                              = try(each.value.role_assignments, null)
}
