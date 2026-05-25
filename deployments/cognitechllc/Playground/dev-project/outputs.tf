# Outputs from the deployment
# These are passed through from the formation module

# Organization outputs - uncomment when org module is enabled
# output "folders" {
#   description = "Created folder resources"
#   value       = module.playground_dev.folders
# }

# output "nested_folders" {
#   description = "Created nested folder resources"
#   value       = module.playground_dev.nested_folders
# }

# output "projects" {
#   description = "Created project resources with full details"
#   value       = module.playground_dev.projects
#   sensitive   = true
# }

# output "project_ids" {
#   description = "Map of project keys to project IDs"
#   value       = module.playground_dev.project_ids
# }

# output "project_numbers" {
#   description = "Map of project keys to project numbers"
#   value       = module.playground_dev.project_numbers
# }

output "service_accounts" {
  description = "Created service accounts"
  value       = module.playground_dev.service_accounts
  sensitive   = true
}

output "service_account_emails" {
  description = "Service account email addresses"
  value       = module.playground_dev.service_account_emails
}

output "custom_roles" {
  description = "Created custom roles"
  value       = module.playground_dev.custom_roles
}

# Summary output for easy reference
output "deployment_summary" {
  description = "High-level summary of the deployment"
  value       = module.playground_dev.deployment_summary
}
