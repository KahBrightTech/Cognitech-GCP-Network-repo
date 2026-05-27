#--------------------------------------------------------------------
# PLAYGROUND DEV PROJECT DEPLOYMENT
# Uses the tenant-projects formation as a reusable module
#--------------------------------------------------------------------

module "playground_dev" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Network-repo.git//formations/tenant-projects?ref=main"
  iam    = var.iam
}

