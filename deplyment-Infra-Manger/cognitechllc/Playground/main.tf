# # Main deployment file that orchestrates multiple formations
# # This deployment creates organizational structure and applies IAM

# # Create organizational structure (folders and projects)
# module "org" {
#   source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/Org?ref=v1.0.0"

#   org = var.org
# }

# Apply IAM policies to the created resources
module "iam" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"

  iam = var.iam

  # Ensure IAM is applied after org resources are created
  depends_on = [module.org]
}
