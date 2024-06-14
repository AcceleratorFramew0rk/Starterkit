module "public_ip_firewall1" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.1.0"
  
  enable_telemetry    = var.enable_telemetry
  resource_group_name = azurerm_resource_group.this.name
  name                = "${module.naming.public_ip.name_unique}-fw1"
  location            = azurerm_resource_group.this.location 
}

module "firewall" {
  source  = "Azure/avm-res-network-azurefirewall/azurerm"
  version = "0.1.4"
  
  name                = "${module.naming.firewall.name}-ingress-internet"
  enable_telemetry    = var.enable_telemetry
  location            = azurerm_resource_group.this.location
  resource_group_name = try(local.remote.resource_group.name, null) != null ? local.remote.resource_group.name : var.platform_resource_group_name # firewall must be in the same resource group as virtual network and subnets
  firewall_sku_tier   = "Premium" # "Basic"  # "Standard"
  firewall_policy_id  = module.firewall_policy.resource.id # bug in avm module which output resource to id or name variable
  firewall_sku_name   = "AZFW_VNet"
  firewall_zones      = ["1", "2", "3"]
  firewall_ip_configuration = [
    {
      name                 = "ipconfig1"
      # subnet_id            = local.remote.networking.virtual_networks.hub_internet_ingress.virtual_subnets.subnets["AzureFirewallSubnet"].id # module.virtualnetwork_ingress_ingress.subnets["AzureFirewallSubnet"].id  # azurerm_subnet.subnet.id
      subnet_id            = try(local.remote.networking.virtual_networks.hub_internet_ingress.virtual_subnets.subnets["AzureFirewallSubnet"].id, null) != null ? local.remote.networking.virtual_networks.hub_internet_ingress.virtual_subnets.subnets["AzureFirewallSubnet"].id : var.subnet_id 
      public_ip_address_id = module.public_ip_firewall1.public_ip_id # azurerm_public_ip.public_ip.id
    }
  ]

  tags        = merge(
    local.global_settings.tags,
    {
      purpose = "hub internet ingress firewall" 
      project_code = try(local.global_settings.prefix, var.prefix) 
      env = try(local.global_settings.environment, var.environment) 
      zone = "hub internet"
      tier = "na"   
    }
  )

  depends_on = [
    module.public_ip_firewall1,
    module.firewall_policy        
  ]
}
