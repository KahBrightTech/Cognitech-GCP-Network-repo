# Terraform variables file
# Generated from: deplyment-Infra-Manger/cognitechllc/Environment-Config/Playgroud/dev-project/deployment-config.yaml
# This file contains the actual variable values for the IAM module deployment

common = {
  project_id = "dev-project-1430"
  region     = "us-central1"
  labels = {
    environment = "dev"
    tenant      = "cognitechllc"
  }
}

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
      disabled     = false
    }
    app_backend = {
      account_id   = "app-backend-sa"
      display_name = "Backend Application Service Account"
      description  = "Service account for backend application workloads"
      disabled     = false
    }
    web_backend = {
      account_id   = "web-backend-sa"
      display_name = "Backend Application Service Account"
      description  = "Service account for backend application workloads"
      disabled     = false
    }
  }

  # Project-level IAM bindings (assigns roles to multiple members at once)
  project_iam_bindings = {
    # Assign custom app_deployer role to platform engineer
    platform_engineer_deployer = {
      role_key = "app_deployer" # References custom_roles["app_deployer"]
      members = [
        "user:kbrigthain@gmail.com" # Platform engineer gets custom deployer role
      ]
    }
    # Assign custom network_viewer role to service accounts
    backend_network_viewers = {
      role_key = "network_viewer" # References custom_roles["network_viewer"]
      member_keys = [
        "app_backend", # References service_accounts["app_backend"]
        "ci_cd",       # References service_accounts["ci_cd"]
        "web_backend"  # References service_accounts["web_backend"]
      ]
    }
    # Assign standard compute.viewer role to user and service account
    compute_viewers = {
      role = "roles/compute.viewer" # Standard GCP role
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
    dev_team_app_deployer = {
      role_key = "app_deployer" # References custom_roles["app_deployer"]
      member   = "user:kbrigthain3@gmail.com"
    }
    # Assign custom network_viewer role to CI/CD service account
    ci_cd_network_viewer = {
      role_key   = "network_viewer" # References custom_roles["network_viewer"]
      member_key = "ci_cd"          # References service_accounts["ci_cd"]
    }
    # Assign standard editor role to platform engineer
    platform_engineer_editor = {
      role   = "roles/editor" # Standard GCP role
      member = "user:kbrigthain@gmail.com"
    }
  }

  # Organization and folder IAM bindings (empty for dev environment)
  organization_iam_bindings = {}
  folder_iam_bindings       = {}
}

s3 = {
  project_id = "my-gcp-project-id"
  location   = "us-central1"

  buckets = {
    tfstate = {
      name                        = "my-gcp-project-id-us-central1-state-1234"
      storage_class               = "STANDARD"
      force_destroy               = false
      uniform_bucket_level_access = true
      public_access_prevention    = "enforced"
      versioning_enabled          = true

      labels = {
        environment = "dev"
        managed_by  = "terraform"
      }

      lifecycle_rules = [
        {
          action_type                = "Delete"
          days_since_noncurrent_time = 30
        }
      ]

      iam_members = {
        infra_manager_sa = {
          role   = "roles/storage.admin"
          member = "infra-manager-sa@dev-project-1430.iam.gserviceaccount.com"
        }
      }
    }

    app_assets = {
      name               = "my-gcp-project-id-assets-1234"
      storage_class      = "STANDARD"
      versioning_enabled = false

      iam_bindings = {
        "roles/storage.objectViewer" = [
          "group:kbrigthain3@gmail.com"
        ]
      }
    }
  }
}