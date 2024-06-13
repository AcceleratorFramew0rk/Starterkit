locals {
  endpoints = toset(["blob"])  
}

module "private_dns_zones" {
  source                = "Azure/avm-res-network-privatednszone/azurerm"  

  enable_telemetry      = true
  resource_group_name   = azurerm_resource_group.this.name
  domain_name           = "privatelink.blob.core.windows.net"
  # number_of_record_sets = 2
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

resource "azurerm_user_assigned_identity" "this_identity" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

data "azurerm_role_definition" "this" {
  name = "Contributor"
}

#create azure storage account
module "storageaccount" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.1.3"

  account_replication_type      = "LRS" # "GRS"
  account_tier                  = "Standard"
  account_kind                  = "StorageV2"
  location                      = azurerm_resource_group.this.location
  name                          = "${module.naming.storage_account.name_unique}${random_string.this.result}"
  resource_group_name           = azurerm_resource_group.this.name
  min_tls_version               = "TLS1_2"
  shared_access_key_enabled     = true
  public_network_access_enabled = true
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this_identity.id]
  }
  tags = { 
    purpose = "storage account" 
    project_code = try(local.global_settings.prefix, var.prefix) 
    env = try(local.global_settings.environment, var.environment) 
    zone = "project"
    tier = "db"           
  }     
  /*lock = {
    name = "lock"
    kind = "None"
  } */
  role_assignments = {
    role_assignment_1 = {
      role_definition_id_or_name       = "Contributor" # data.azurerm_role_definition.this.id
      principal_id                     = data.azurerm_client_config.current.object_id
      skip_service_principal_aad_check = false
    },
    role_assignment_2 = {
      role_definition_id_or_name       = "Owner"
      principal_id                     = data.azurerm_client_config.current.object_id
      skip_service_principal_aad_check = false
    },

  }

  network_rules = {
    bypass                     = ["AzureServices"]
    default_action             = "Deny"
    #ip_rules                   = [try(module.public_ip[0].public_ip, var.bypass_ip_cidr)]
    #virtual_network_subnet_ids = toset([azurerm_subnet.private.id])
  }

  #create a private endpoint for each endpoint type
  # private_endpoints = {
  #   for endpoint in local.endpoints :
  #   endpoint => {
  #     # the name must be set to avoid conflicting resources.
  #     name                          = "pe-${endpoint}-${module.naming.storage_account.name_unique}"
  #     subnet_resource_id            = try(local.remote.networking.virtual_networks.spoke_project.virtual_subnets.subnets["DbSubnet"].id, null) != null ? local.remote.networking.virtual_networks.spoke_project.virtual_subnets.subnets["DbSubnet"].id : var.subnet_id  
  #     subresource_name              = [endpoint]
  #     private_dns_zone_resource_ids = [module.private_dns_zones.private_dnz_zone_output.id] 
  #     # these are optional but illustrate making well-aligned service connection & NIC names.
  #     private_service_connection_name = "psc-${endpoint}-${module.naming.storage_account.name_unique}"
  #     network_interface_name          = "nic-pe-${endpoint}-${module.naming.storage_account.name_unique}"
  #     inherit_tags                    = false
  #     inherit_lock                    = false

  #     tags = {
  #       env = try(local.global_settings.environment, var.environment) 
  #     }

  #     role_assignments = {
  #       role_assignment_1 = {
  #         role_definition_id_or_name = data.azurerm_role_definition.this.id
  #         principal_id               = data.azurerm_client_config.current.object_id
  #       }
  #     }
  #   }
  # }

  # network_rules {
  #   default_action             = "Deny" # "Allow" -> "Deny"
  #     # (3 unchanged attributes hidden)
  # }

  private_endpoints = {
    for endpoint in local.endpoints :
    endpoint => {
      # the name must be set to avoid conflicting resources.
      name                          = "pe-${endpoint}-${module.naming.storage_account.name_unique}"
      # subnet_resource_id            = azurerm_subnet.private.id
      subnet_resource_id            = try(local.remote.networking.virtual_networks.spoke_project.virtual_subnets.subnets["DbSubnet"].id, null) != null ? local.remote.networking.virtual_networks.spoke_project.virtual_subnets.subnets["DbSubnet"].id : var.subnet_id  
      subresource_name              = endpoint
      # private_dns_zone_resource_ids = [azurerm_private_dns_zone.this[endpoint].id]
      private_dns_zone_resource_ids = [module.private_dns_zones.private_dnz_zone_output.id] 
      # these are optional but illustrate making well-aligned service connection & NIC names.
      private_service_connection_name = "psc-${endpoint}-${module.naming.storage_account.name_unique}"
      network_interface_name          = "nic-pe-${endpoint}-${module.naming.storage_account.name_unique}"
      inherit_lock                    = false

      tags = {
        env   = "Prod"
        owner = "Matt "
        dept  = "IT"
      }

      role_assignments = {
        role_assignment_1 = {
          role_definition_id_or_name = "Contributor" # data.azurerm_role_definition.example.name
          principal_id               = data.azurerm_client_config.current.object_id # coalesce(var.msi_id, data.azurerm_client_config.current.object_id)
        }
      }
    }
  }

  depends_on = [
    module.private_dns_zones,
  ]
}

