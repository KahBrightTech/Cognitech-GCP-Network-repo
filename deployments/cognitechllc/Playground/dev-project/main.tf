#--------------------------------------------------------------------
# PLAYGROUND DEV PROJECT DEPLOYMENT
# Uses the tenant-projects formation as a reusable module
#--------------------------------------------------------------------

module "playground_dev" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Network-repo.git//formations/tenant-projects?ref=main"
  iam = merge(
    var.iam,
    {
      project_id = coalesce(var.iam.project_id, var.common.project_id)
    }
  )
}

