# Google Cloud provider configuration

provider "google" {
  # When using Infrastructure Manager, authentication is handled automatically
  # via the service account specified in deployment-config.yaml

  # Optional: Set default project and region
  # project = var.default_project_id
  # region  = var.default_region
}
