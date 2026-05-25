# Outputs from the deployment
# These can be used by other deployments or for reference

# Organization outputs - uncomment when org module is enabled
# output "folders" {
#   description = "Created folder resources"
#   value       = module.org.folders
# }

# output "nested_folders" {
#   description = "Created nested folder resources"
#   value       = module.org.nested_folders
# }

# output "projects" {
#   description = "Created project resources with full details"
#   value       = module.org.projects
#   sensitive   = true
# }

# output "project_ids" {
#   description = "Map of project keys to project IDs"
#   value       = module.org.project_ids
# }

# output "project_numbers" {
#   description = "Map of project keys to project numbers"
#   value       = module.org.project_numbers
# }

output "service_accounts" {
  description = "Created service accounts"
  value       = module.iam.service_accounts
  sensitive   = true
}

output "service_account_emails" {
  description = "Service account email addresses"
  value       = module.iam.service_account_emails
}

output "custom_roles" {
  description = "Created custom roles"
  value       = module.iam.custom_roles
}

# Summary output for easy reference
output "deployment_summary" {
  description = "High-level summary of the deployment"
  value = {
    # folders_created          = length(module.org.folders)
    # nested_folders_created   = length(module.org.nested_folders)
    # projects_created         = length(module.org.projects)
    service_accounts_created = length(module.iam.service_accounts)
    custom_roles_created     = length(module.iam.custom_roles)
  }
}
