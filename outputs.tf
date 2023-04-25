output "hub_resource_group_id" {
  value       = module.hub_resource_group.id
  description = "The ID of the hub resource group."
}

output "spoke1_resource_group_id" {
  value       = module.spoke1_resource_group.id
  description = "The ID of the spoke1 resource group."
}

output "shared_services_resource_group_id" {
  value       = module.shared_services_resource_group.id
  description = "The ID of the shared services resource group."
}

output "shared_services_log_analytics_workspace_resource_id" {
  description = "The resource ID of the Shared Services Log Analytics Workspace."
  value       = module.shared_services_log_analytics_workspace.workspace_resource_id
}

output "shared_services_log_analytics_workspace_id" {
  description = "The workspace ID (Customer ID) of the Shared Services Log Analytics Workspace."
  value       = module.shared_services_log_analytics_workspace.workspace_id
}
