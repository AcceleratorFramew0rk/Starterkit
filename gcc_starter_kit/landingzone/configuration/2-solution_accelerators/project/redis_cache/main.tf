module "private_dns_zones" {
  source                = "Azure/avm-res-network-privatednszone/azurerm"  

  enable_telemetry      = true
  resource_group_name   = azurerm_resource_group.this.name
  domain_name           = "privatelink.redis.cache.windows.net"
  dns_zone_tags         = {
      env = try(local.global_settings.environment, var.environment) 
    }
  virtual_network_links = {
      vnetlink1 = {
        vnetlinkname     = "vnetlink1"
        vnetid           = try(local.remote.networking.virtual_networks.spoke_project.virtual_network.id, null) != null ? local.remote.networking.virtual_networks.spoke_project.virtual_network.id : var.vnet_id  
        autoregistration = false # true
        tags = {
          env = try(local.global_settings.environment, var.environment) 
        }
      }
    }
}

module "private_endpoint" {
  source = "./../../../../../../modules/networking/terraform-azurerm-privateendpoint"
  
  name                           = "${module.redis_cache.resource.name}PrivateEndpoint"
  location                       = azurerm_resource_group.this.location
  resource_group_name            = azurerm_resource_group.this.name
  subnet_id                      = try(local.remote.networking.virtual_networks.spoke_project.virtual_subnets.subnets["DbSubnet"].id, null) != null ? local.remote.networking.virtual_networks.spoke_project.virtual_subnets.subnets["DbSubnet"].id : var.subnet_id 
  tags                           = {
      env = try(local.global_settings.environment, var.environment)  
    }
  private_connection_resource_id = module.redis_cache.resource.id
  is_manual_connection           = false
  subresource_name               = "redisCache"
  private_dns_zone_group_name    = "default"
  private_dns_zone_group_ids     = [module.private_dns_zones.private_dnz_zone_output.id] 
  depends_on = [
    module.private_dns_zones,
    module.redis_cache
  ]
}

module "redis_cache" {
  source = "./../../../../../../modules/databases/terraform-azurerm-redis-cache"

  name                         = "${module.naming.redis_cache.name}${random_string.this.result}" 
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  tags = { 
    purpose = "redis cache" 
    project_code = try(local.global_settings.prefix, var.prefix) 
    env = try(local.global_settings.environment, var.environment) 
    zone = "project"
    tier = "db"           
  } 
  # add the variables here
  capacity                      = 1  
  family                        = "P"
  sku_name                      = "Premium"
  shard_count                   = 1
  public_network_access_enabled = false  
  redis_configuration = {
    rdb_backup_enabled = false
  }

}


