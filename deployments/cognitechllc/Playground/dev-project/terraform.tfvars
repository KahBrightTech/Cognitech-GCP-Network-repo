# Terraform variables file
# Generated from: deplyment-Infra-Manger/cognitechllc/Environment-Config/Playgroud/dev-project/deployment-config.yaml
# This file contains the actual variable values for the IAM module deployment

iam = {
  # Project and Organization IDs
  project_id      = "dev-project-1430"
  organization_id = "43129013392"


  # Custom IAM roles with keys for cross-referencing
  custom_roles = {
    app_deployer = {
      role_id     = "appDeployer"
      title       = "Application Deployer"
      description = "Custom role for deploying applications with limited permissions"
      permissions = [
        "compute.instances.create",
        "compute.instances.delete",
        "compute.instances.start",
        "compute.instances.stop",
        "storage.buckets.get",
        "storage.objects.create",
        "storage.objects.delete"
      ]
      stage = "GA"
    }
    network_viewer = {
      role_id     = "networkViewer"
      title       = "Network Configuration Viewer"
      description = "Read-only access to network configurations"
      permissions = [
        "compute.networks.get",
        "compute.networks.list",
        "compute.subnetworks.get",
        "compute.subnetworks.list",
        "compute.firewalls.get",
        "compute.firewalls.list"
      ]
      stage = "GA"
    }
  }

  # Service accounts with keys for cross-referencing
  service_accounts = {
    ci_cd = {
      account_id   = "ci-cd-pipeline-sa"
      display_name = "CI/CD Pipeline Service Account"
      description  = "Service account for automated CI/CD deployments"
      project_id   = "dev-project-1430"
      disabled     = false
    }
    app_backend = {
      account_id   = "app-backend-sa"
      display_name = "Backend Application Service Account"
      description  = "Service account for backend application workloads"
      project_id   = "dev-project-1430"
      disabled     = false
    }
  }

  # Project-level IAM bindings (assigns roles to multiple members at once)
  project_iam_bindings = {
    # Assign custom app_deployer role to platform engineer
    platform_engineer_deployer = {
      project_id = "dev-project-1430"
      role_key   = "app_deployer" # References custom_roles["app_deployer"]
      members = [
        "user:kbrigthain@gmail.com" # Platform engineer gets custom deployer role
      ]
    }
    # Assign custom network_viewer role to service accounts
    backend_network_viewers = {
      project_id = "dev-project-1430"
      role_key   = "network_viewer" # References custom_roles["network_viewer"]
      member_keys = [
        "app_backend", # References service_accounts["app_backend"]
        "ci_cd"        # References service_accounts["ci_cd"]
      ]
    }
    # Assign standard compute.viewer role to user and service account
    compute_viewers = {
      project_id = "dev-project-1430"
      role       = "roles/compute.viewer" # Standard GCP role
      members = [
        "user:kbrigthain3@gmail.com"
      ]
      member_keys = [
        "app_backend" # Add service account by key reference
      ]
    }
  }

  # Project-level IAM members (assigns roles to individual members)
  project_iam_members = {
    # Assign custom app_deployer role to dev team user
    dev_team_deployer = {
      project_id = "dev-project-1430"
      role_key   = "app_deployer" # References custom_roles["app_deployer"]
      member     = "user:kbrigthain3@gmail.com"
    }
    # Assign custom network_viewer role to CI/CD service account
    cicd_network_viewer = {
      project_id = "dev-project-1430"
      role_key   = "network_viewer" # References custom_roles["network_viewer"]
      member_key = "ci_cd"          # References service_accounts["ci_cd"]
    }
    # Assign standard editor role to platform engineer
    platform_engineer_editor = {
      project_id = "dev-project-1430"
      role       = "roles/editor" # Standard GCP role
      member     = "user:kbrigthain@gmail.com"
    }
    # Test entry to verify create actions appear in preview/apply output
    platform_engineer_logging_viewer = {
      project_id = "dev-project-1430"
      role       = "roles/logging.viewer"
      member     = "user:kbrigthain@gmail.com"
    }
  }

  # Organization and folder IAM bindings (empty for dev environment)
  organization_iam_bindings = {}
  folder_iam_bindings       = {}
}
