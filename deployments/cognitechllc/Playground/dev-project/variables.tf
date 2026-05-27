# Input variables for the deployment

variable "common" {
  description = "Common configuration shared across modules"
  type = object({
    project_id = optional(string)
    region     = optional(string)
    labels     = optional(map(string))
  })
  default = {
    project_id = null
    region     = "us-central1"
    labels     = {}
  }
}

# variable "org" {
#   description = "Organization structure configuration including folders and projects"
#   type = object({
#     default_billing_account = optional(string)

#     # Top-level folders
#     folders = optional(map(object({
#       display_name = string
#       parent       = string # Format: "organizations/123456" or "folders/123456"
#     })), {})

#     # Nested folders (child folders)
#     nested_folders = optional(map(object({
#       display_name = string
#       parent_key   = string # Key reference to parent folder in 'folders' map
#     })), {})

#     # Projects within folders
#     projects = optional(map(object({
#       name                = string
#       folder_key          = optional(string) # Key reference to folder
#       billing_account     = optional(string)
#       auto_create_network = optional(bool, false)
#       labels              = optional(map(string), {})
#       apis_to_enable      = optional(list(string), [])
#     })), {})

#     # IAM bindings for folders
#     folder_iam_members = optional(map(object({
#       folder_key = string
#       role       = string
#       member     = string
#     })), {})
#   })
#   default = {
#     folders            = {}
#     nested_folders     = {}
#     projects           = {}
#     folder_iam_members = {}
#   }
# }

variable "iam" {
  description = "IAM configuration for projects, service accounts, and roles"
  type = object({
    project_id      = optional(string)
    organization_id = optional(string)

    # Project-level IAM bindings
    project_iam_bindings = optional(map(object({
      project_id  = optional(string)
      role        = optional(string)           # Standard role like "roles/viewer" OR custom role key from custom_roles
      role_key    = optional(string)           # Reference to custom_roles map key (alternative to role)
      members     = optional(list(string), []) # List of members: "user:...", "serviceAccount:...", or "@sa_key"
      member_keys = optional(list(string), []) # List of service_accounts map keys to add as members
      condition = optional(object({
        title       = string
        description = optional(string)
        expression  = string
      }))
    })), {})

    # Project-level IAM members
    project_iam_members = optional(map(object({
      project_id = optional(string)
      role       = optional(string) # Standard role like "roles/viewer" OR custom role key from custom_roles
      role_key   = optional(string) # Reference to custom_roles map key (alternative to role)
      member     = optional(string) # Member: "user:...", "serviceAccount:...", or "@sa_key"
      member_key = optional(string) # Reference to service_accounts map key (alternative to member)
      condition = optional(object({
        title       = string
        description = optional(string)
        expression  = string
      }))
    })), {})

    # Service Accounts
    service_accounts = optional(map(object({
      key          = optional(string) # Optional alias key for referencing in IAM bindings (defaults to map key)
      account_id   = string           # Required: Service account ID
      display_name = optional(string)
      description  = optional(string)
      project_id   = optional(string)
      disabled     = optional(bool, false)
    })), {})

    # Custom Roles
    custom_roles = optional(map(object({
      key         = optional(string) # Optional alias key for referencing in IAM bindings (defaults to map key)
      role_id     = string           # Required: Role ID for GCP
      title       = string
      description = optional(string)
      permissions = list(string)
      stage       = optional(string, "GA")
    })), {})

    # Organization-level IAM
    organization_iam_bindings = optional(map(object({
      role    = string
      members = list(string)
    })), {})

    # Folder-level IAM
    folder_iam_bindings = optional(map(object({
      folder  = string
      role    = string
      members = list(string)
    })), {})
  })
  default = {
    project_iam_bindings = {}
    project_iam_members  = {}
    service_accounts     = {}
    custom_roles         = {}
  }
}

variable "s3" {
  description = "Cloud Storage configuration including project, location, buckets, and IAM"
  type = object({
    project_id = string
    location   = optional(string)

    buckets = optional(map(object({
      name                        = string
      storage_class               = optional(string)
      labels                      = optional(map(string))
      force_destroy               = optional(bool)
      uniform_bucket_level_access = optional(bool)
      public_access_prevention    = optional(string)
      versioning_enabled          = optional(bool)

      retention_policy = optional(object({
        retention_period = number
        is_locked        = optional(bool)
      }))

      lifecycle_rules = optional(list(object({
        action_type                = string
        action_storage_class       = optional(string)
        age                        = optional(number)
        created_before             = optional(string)
        with_state                 = optional(string)
        matches_storage_class      = optional(list(string))
        num_newer_versions         = optional(number)
        custom_time_before         = optional(string)
        days_since_custom_time     = optional(number)
        days_since_noncurrent_time = optional(number)
        noncurrent_time_before     = optional(string)
        matches_prefix             = optional(list(string))
        matches_suffix             = optional(list(string))
      })))

      iam_bindings = optional(map(list(string)))
      iam_members = optional(map(object({
        role   = string
        member = string
        condition = optional(object({
          title       = string
          description = string
          expression  = string
        }))
      })))
    })))
  })
  default = {
    project_id = ""
    location   = "us-central1"
    buckets    = {}
  }
}