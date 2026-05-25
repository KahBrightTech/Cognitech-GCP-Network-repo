# Input variables for the deployment

variable "org" {
  description = "Organization structure configuration including folders and projects"
  type = object({
    default_billing_account = optional(string)

    # Top-level folders
    folders = optional(map(object({
      display_name = string
      parent       = string # Format: "organizations/123456" or "folders/123456"
    })), {})

    # Nested folders (child folders)
    nested_folders = optional(map(object({
      display_name = string
      parent_key   = string # Key reference to parent folder in 'folders' map
    })), {})

    # Projects within folders
    projects = optional(map(object({
      name                = string
      folder_key          = optional(string) # Key reference to folder
      billing_account     = optional(string)
      auto_create_network = optional(bool, false)
      labels              = optional(map(string), {})
      apis_to_enable      = optional(list(string), [])
    })), {})

    # IAM bindings for folders
    folder_iam_members = optional(map(object({
      folder_key = string
      role       = string
      member     = string
    })), {})
  })
  default = {
    folders            = {}
    nested_folders     = {}
    projects           = {}
    folder_iam_members = {}
  }
}

variable "iam" {
  description = "IAM configuration for projects, service accounts, and roles"
  type = object({
    project_id      = optional(string)
    organization_id = optional(string)

    # Project-level IAM bindings
    project_iam_bindings = optional(map(object({
      project_id = string
      role       = string
      members    = list(string)
      condition = optional(object({
        title       = string
        description = optional(string)
        expression  = string
      }))
    })), {})

    # Project-level IAM members
    project_iam_members = optional(map(object({
      project_id = optional(string)
      role       = string
      member     = string
      condition = optional(object({
        title       = string
        description = optional(string)
        expression  = string
      }))
    })), {})

    # Service Accounts
    service_accounts = optional(map(object({
      account_id   = optional(string)
      display_name = optional(string)
      description  = optional(string)
      project_id   = optional(string)
      disabled     = optional(bool, false)
    })), {})

    # Custom Roles
    custom_roles = optional(map(object({
      role_id     = string
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
