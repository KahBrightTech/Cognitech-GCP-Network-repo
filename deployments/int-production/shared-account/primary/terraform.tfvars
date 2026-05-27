# Example deployment configuration for int-production/shared-account/primary
# This creates a folder hierarchy with nested projects and applies IAM

org = {
  default_billing_account = "01234-56789A-BCDEF0" # Replace with your billing account

  # Top-level folders under the organization
  folders = {
    "production" = {
      display_name = "Production"
      parent       = "organizations/123456789012" # Replace with your org ID
    }
    "shared-services" = {
      display_name = "Shared Services"
      parent       = "organizations/123456789012"
    }
  }

  # Nested folders (children of top-level folders)
  nested_folders = {
    "prod-networking" = {
      display_name = "Networking"
      parent_key   = "production" # References the 'production' folder above
    }
    "prod-security" = {
      display_name = "Security"
      parent_key   = "production"
    }
    "shared-monitoring" = {
      display_name = "Monitoring"
      parent_key   = "shared-services"
    }
  }

  # Projects nested within folders
  projects = {
    "prod-network-hub" = {
      name                = "cognitech-prod-network-hub"
      folder_key          = "prod-networking" # References nested_folders key
      billing_account     = "01234-56789A-BCDEF0"
      auto_create_network = false
      labels = {
        environment = "production"
        team        = "networking"
        cost-center = "infrastructure"
      }
      apis_to_enable = [
        "compute.googleapis.com",
        "servicenetworking.googleapis.com",
        "dns.googleapis.com",
        "networkmanagement.googleapis.com"
      ]
    }

    "prod-network-spoke-1" = {
      name                = "cognitech-prod-spoke-1"
      folder_key          = "prod-networking"
      billing_account     = "01234-56789A-BCDEF0"
      auto_create_network = false
      labels = {
        environment = "production"
        team        = "app-team-1"
        spoke       = "spoke-1"
      }
      apis_to_enable = [
        "compute.googleapis.com",
        "servicenetworking.googleapis.com"
      ]
    }

    "prod-security-logging" = {
      name                = "cognitech-prod-security-logs"
      folder_key          = "prod-security"
      billing_account     = "01234-56789A-BCDEF0"
      auto_create_network = false
      labels = {
        environment = "production"
        team        = "security"
        purpose     = "logging"
      }
      apis_to_enable = [
        "logging.googleapis.com",
        "monitoring.googleapis.com",
        "securitycenter.googleapis.com"
      ]
    }

    "shared-monitoring-hub" = {
      name                = "cognitech-shared-monitoring"
      folder_key          = "shared-monitoring"
      billing_account     = "01234-56789A-BCDEF0"
      auto_create_network = false
      labels = {
        environment = "shared"
        team        = "sre"
        purpose     = "monitoring"
      }
      apis_to_enable = [
        "monitoring.googleapis.com",
        "logging.googleapis.com",
        "cloudtrace.googleapis.com"
      ]
    }
  }

  # Folder-level IAM bindings
  folder_iam_members = {
    "prod-folder-admin" = {
      folder_key = "production"
      role       = "roles/resourcemanager.folderAdmin"
      member     = "group:prod-admins@cognitechllc.org"
    }
    "prod-folder-viewer" = {
      folder_key = "production"
      role       = "roles/viewer"
      member     = "group:developers@cognitechllc.org"
    }
    "shared-folder-viewer" = {
      folder_key = "shared-services"
      role       = "roles/viewer"
      member     = "group:all-engineers@cognitechllc.org"
    }
  }
}

# IAM configuration for projects and service accounts
iam = {
  # Note: We use project IDs from the org module output in practice
  # For this example, we're showing the structure

  # Service accounts for network management
  service_accounts = {
    "network-admin-sa" = {
      account_id   = "network-admin-sa"
      display_name = "Network Administration Service Account"
      description  = "Service account for managing VPC networks and firewall rules"
      project_id   = "cognitech-prod-network-hub"
    }
    "security-scanner-sa" = {
      account_id   = "security-scanner-sa"
      display_name = "Security Scanner Service Account"
      description  = "Service account for running security scans"
      project_id   = "cognitech-prod-security-logs"
    }
    "monitoring-collector-sa" = {
      account_id   = "monitoring-collector-sa"
      display_name = "Monitoring Collector Service Account"
      description  = "Service account for collecting monitoring data"
      project_id   = "cognitech-shared-monitoring"
    }
  }

  # Project-level IAM members
  project_iam_members = {
    # Network Hub permissions
    "network-hub-compute-admin" = {
      project_id = "cognitech-prod-network-hub"
      role       = "roles/compute.networkAdmin"
      member     = "serviceAccount:network-admin-sa@cognitech-prod-network-hub.iam.gserviceaccount.com"
    }
    "network-hub-team-access" = {
      project_id = "cognitech-prod-network-hub"
      role       = "roles/viewer"
      member     = "group:network-team@cognitechllc.org"
    }

    # Spoke project permissions
    "spoke1-app-team-editor" = {
      project_id = "cognitech-prod-spoke-1"
      role       = "roles/editor"
      member     = "group:app-team-1@cognitechllc.org"
    }

    # Security project permissions
    "security-logs-writer" = {
      project_id = "cognitech-prod-security-logs"
      role       = "roles/logging.logWriter"
      member     = "serviceAccount:security-scanner-sa@cognitech-prod-security-logs.iam.gserviceaccount.com"
    }
    "security-team-admin" = {
      project_id = "cognitech-prod-security-logs"
      role       = "roles/logging.admin"
      member     = "group:security-team@cognitechllc.org"
    }

    # Monitoring project permissions
    "monitoring-metrics-writer" = {
      project_id = "cognitech-shared-monitoring"
      role       = "roles/monitoring.metricWriter"
      member     = "serviceAccount:monitoring-collector-sa@cognitech-shared-monitoring.iam.gserviceaccount.com"
    }
  }

  # Custom role for network operations
  custom_roles = {
    "network-operator" = {
      role_id     = "networkOperator"
      title       = "Network Operator"
      description = "Custom role for day-to-day network operations"
      permissions = [
        "compute.networks.get",
        "compute.networks.list",
        "compute.subnetworks.get",
        "compute.subnetworks.list",
        "compute.firewalls.get",
        "compute.firewalls.list",
        "compute.routes.get",
        "compute.routes.list"
      ]
      stage = "GA"
    }
  }

  # Folder-level IAM for cross-project access
  folder_iam_bindings = {
    "prod-folder-network-viewer" = {
      folder = "folders/123456789012" # Replace with actual folder ID after creation
      role   = "roles/compute.networkViewer"
      members = [
        "group:network-team@cognitechllc.org",
        "serviceAccount:network-admin-sa@cognitech-prod-network-hub.iam.gserviceaccount.com"
      ]
    }
  }
}
