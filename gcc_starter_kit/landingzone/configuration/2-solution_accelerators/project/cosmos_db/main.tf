module "private_dns_zones" {
  source                = "Azure/avm-res-network-privatednszone/azurerm"  

  enable_telemetry      = true
  resource_group_name   = azurerm_resource_group.this.name
  domain_name           = "privatelink.documents.azure.com"

  dns_zone_tags        = merge(
    local.global_settings.tags,
    {
      purpose = "consmos db private dns zone" 
      project_code = try(local.global_settings.prefix, var.prefix) 
      env = try(local.global_settings.environment, var.environment) 
      zone = "project"
      tier = "db"   
    }
  ) 

  virtual_network_links = {
      vnetlink1 = {
        vnetlinkname     = "vnetlink1"
        vnetid           = try(local.remote.networking.virtual_networks.spoke_project.virtual_network.id, null) != null ? local.remote.networking.virtual_networks.spoke_project.virtual_network.id : var.vnet_id  
        autoregistration = false # true

        tags        = merge(
          local.global_settings.tags,
          {
            purpose = "consmos db vnet link" 
            project_code = try(local.global_settings.prefix, var.prefix) 
            env = try(local.global_settings.environment, var.environment) 
            zone = "project"
            tier = "db"   
          }
        ) 

      }
    }
}

module "cosmos_db" {
  # source              = "./../../../../../../modules/databases/terraform-azurerm-cosmosdb"
  source = "AcceleratorFramew0rk/aaf/azurerm//modules/databases/terraform-azurerm-cosmosdb"
  
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  cosmos_account_name = "${module.naming.cosmosdb_account.name}${random_string.this.result}" 
  cosmos_api          = var.cosmos_api
  sql_dbs             = var.sql_dbs
  sql_db_containers   = var.sql_db_containers
  private_endpoint = {
    "pe_endpoint" = {
      dns_zone_group_name             = var.dns_zone_group_name
      dns_zone_rg_name                = azurerm_resource_group.this.name 
      enable_private_dns_entry        = true
      is_manual_connection            = false
      name                            = var.pe_name
      private_service_connection_name = var.pe_connection_name
      subnet_name                     = "CosmosDbSubnet" 
      vnet_name                       = try(local.remote.networking.virtual_networks.spoke_project.virtual_network.name, null) != null ? local.remote.networking.virtual_networks.spoke_project.virtual_network.name : var.vnet_name  
      vnet_rg_name                    = try(local.remote.resource_group.name, null) != null ? local.remote.resource_group.name : var.vnet_resource_group_name  
    }
  }

  # # tags is from local variable in the modules. to fix this - fixed on 13 Jun 2024.
  tags        = merge(
    local.global_settings.tags,
    {
      purpose = "consmos db" 
      project_code = try(local.global_settings.prefix, var.prefix) 
      env = try(local.global_settings.environment, var.environment) 
      zone = "project"
      tier = "db"   
    }
  ) 
  
  depends_on = [
    azurerm_resource_group.this,
    module.private_dns_zones
  ]
}
