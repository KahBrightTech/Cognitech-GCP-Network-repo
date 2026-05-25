#--------------------------------------------------------------------
# PLAYGROUND DEV PROJECT DEPLOYMENT
# Uses the tenant-projects formation as a reusable module
#--------------------------------------------------------------------

module "playground_dev" {
  source = "../../../../formations/tenant-projects"

  # Pass IAM configuration to the formation
  iam = var.iam
  # Uncomment to pass org configuration when needed
  # org = var.org
}
