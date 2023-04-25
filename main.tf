terraform {
  required_version = ">= 0.13"

  backend "azurerm" {
    resource_group_name  = "SharedServicesRG"
    storage_account_name = "mycrapocsto"
    container_name       = "cracontainer"
    key                  = "tfstate/newcraa_lz.tfstate"
  }
}

provider "azurerm" {
    #version = 3.0.2 
    features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
  }
}

module "hub_resource_group" {
  source = "../modules/resource_group"
  name   = "hub-rg"
  location = var.location
  tags = var.tags
}

module "spoke1_resource_group" {
  source = "../modules/resource_group"
  name   = "spoke1-rg"
  location = var.location
  tags = var.tags
}

module "shared_services_resource_group" {
  source = "../modules/resource_group"
  name   = "shared-services-rg"
  location = var.location
  tags = var.tags
}


module "hub_vnet" {
  source                              = "../modules/virtual_network"
  vnet_rg_name                        = module.hub_resource_group.name
  vnet_name                           = "hub-vnet"
  vnet_address_space                  = ["10.0.0.0/16"]
  location                            = var.location
  tags                                = var.tags
  enable_diagnostic_settings          = true
  network_watcher_name                = "NetworkWatcher_eastus2"
  network_watcher_resource_group_name = "NetworkWatcherRG"
  log_analytics_workspace_id          = module.shared_services_log_analytics_workspace.workspace_id
  log_analytics_workspace_name        = "shared-services-law"
  log_analytics_workspace_location    = var.location
  log_analytics_workspace_resource_id = module.shared_services_log_analytics_workspace.workspace_resource_id
  storage_account_id                  = module.hub_storage_account.storage_account_id
  storage_account_name                = "hubstgacct"
}

module "spoke1_nsg" {
  source              = "../modules/network_security_group"
  name                = "spoke1-nsg"
  location            = module.spoke1_resource_group.location
  resource_group_name = module.spoke1_resource_group.name
  create_nsg          = true
}

module "spoke1_vnet" {
  source                          = "../modules/virtual_network"
  vnet_rg_name                    = module.spoke1_resource_group.name
  location                        = module.spoke1_resource_group.location
  vnet_name                       = "spoke1-vnet"
  vnet_address_space              = ["10.1.0.0/16"]
  tags                            = var.tags
  enable_diagnostic_settings      = true
  network_watcher_name                = "NetworkWatcher_eastus2"
  network_watcher_resource_group_name = "NetworkWatcherRG"
  #log_analytics_workspace_name        = module.shared_services_log_analytics_workspace.workspace_name
  log_analytics_workspace_name        = "shared-services-law"
  log_analytics_workspace_id      = module.shared_services_log_analytics_workspace.workspace_id
  log_analytics_workspace_location = var.location
  log_analytics_workspace_resource_id = module.shared_services_log_analytics_workspace.workspace_resource_id
  storage_account_id              = module.hub_storage_account.storage_account_id
  storage_account_name              = module.hub_storage_account.storage_account_name
  nsg_id                          = module.spoke1_nsg.nsg_id
}

module "spoke1_subnet" {
  source                  = "../modules/subnet"
  subnet_name             = "spoke1-subnet"
  subnet_rg_name          = module.spoke1_resource_group.name
  vnet_name               = module.spoke1_vnet.vnet_name
  subnet_address_prefixes = ["10.1.1.0/24"]
  create_nsg              = true
  nsg_id                  = module.spoke1_nsg.nsg_id
}


module "hub_vnet_to_spoke1_vnet_peering" {
  source                   = "../modules/virtual_network_peering"
  hub_vnet_name            = module.hub_vnet.vnet_name
  hub_vnet_resource_group  = module.hub_resource_group.name
  spoke_vnet_name          = module.spoke1_vnet.vnet_name
  spoke_vnet_resource_group = module.spoke1_resource_group.name
  hub_vnet_id              = module.hub_vnet.vnet_id
  spoke_vnet_id            = module.spoke1_vnet.vnet_id
  reverse_peering          = true
  hub_vnet_dependency      = module.hub_vnet.main
  spoke_vnet_dependency    = module.spoke1_vnet.main
}

module "hub_storage_account" {
  source                   = "../modules/storage_account"
  resource_group_name      = module.hub_resource_group.name
  name                     = "hubstgacct"
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
  log_analytics_workspace_id = module.shared_services_log_analytics_workspace.workspace_id
}

module "shared_services_log_analytics_workspace" {
  source              = "../modules/log_analytics_workspace"
  name                = "shared-services-law"
  location            = var.location
  resource_group_name = module.shared_services_resource_group.name
  sku                 = "PerGB2018"
  tags                = var.tags
}


variable "location" {
  default = "East US"
}

variable "tags" {
  default = {
    Owner = "Abdul"
    Support = "Abdul"
    environment = "Dev"
    project     = "POC Landing Zone"
  }
}
