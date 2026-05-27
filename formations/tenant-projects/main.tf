# # Main deployment file that orchestrates multiple formations
# # This deployment creates organizational structure and applies IAM

# # Create organizational structure (folders and projects)
# module "org" {
#   source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/Org?ref=v1.0.0"

#   org = var.org
# }

#--------------------------------------------------------------------
# IAM MODULE - Create custom roles, service accounts, and IAM bindings
# Supports key-based cross-referencing between resources
#--------------------------------------------------------------------
locals {
  custom_role_alias_to_id = var.iam.custom_roles != null ? {
    for k, role in var.iam.custom_roles :
    coalesce(role.key, k) => role.role_id
  } : {}

  service_account_alias_to_account_id = var.iam.service_accounts != null ? {
    for k, sa in var.iam.service_accounts :
    coalesce(sa.key, k) => sa.account_id
  } : {}

  service_account_alias_to_email = var.iam.service_accounts != null ? {
    for k, sa in var.iam.service_accounts :
    coalesce(sa.key, k) => "serviceAccount:${sa.account_id}@${coalesce(sa.project_id, var.iam.project_id)}.iam.gserviceaccount.com"
  } : {}
}

module "iam" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"

  iam = merge(
    var.iam,
    {
      # Upstream IAM module expects custom role map keys as role_id.
      custom_roles = var.iam.custom_roles != null ? {
        for _, role in var.iam.custom_roles :
        role.role_id => {
          title       = role.title
          description = coalesce(role.description, "")
          permissions = role.permissions
          stage       = role.stage
        }
      } : {}

      # Upstream IAM module expects service account map keys as account_id.
      service_accounts = var.iam.service_accounts != null ? {
        for _, sa in var.iam.service_accounts :
        sa.account_id => {
          display_name = coalesce(sa.display_name, sa.account_id)
          description  = sa.description
          disabled     = sa.disabled
        }
      } : {}

      # Transform role/member binding objects into role => members list.
      project_iam_bindings = var.iam.project_iam_bindings != null ? {
        for resolved_role in distinct([
          for _, binding in var.iam.project_iam_bindings : (
            binding.role_key != null ? (
              contains(keys(local.custom_role_alias_to_id), binding.role_key)
              ? "projects/${var.iam.project_id}/roles/${local.custom_role_alias_to_id[binding.role_key]}"
              : binding.role_key
              ) : (
              binding.role != null && contains(keys(local.custom_role_alias_to_id), binding.role)
              ? "projects/${var.iam.project_id}/roles/${local.custom_role_alias_to_id[binding.role]}"
              : binding.role
            )
          )
          if(
            binding.role_key != null ? binding.role_key : binding.role
          ) != null
        ]) :
        resolved_role => distinct(flatten([
          for _, binding in var.iam.project_iam_bindings : (
            (
              binding.role_key != null ? (
                contains(keys(local.custom_role_alias_to_id), binding.role_key)
                ? "projects/${var.iam.project_id}/roles/${local.custom_role_alias_to_id[binding.role_key]}"
                : binding.role_key
                ) : (
                binding.role != null && contains(keys(local.custom_role_alias_to_id), binding.role)
                ? "projects/${var.iam.project_id}/roles/${local.custom_role_alias_to_id[binding.role]}"
                : binding.role
              )
            ) == resolved_role
            ? concat(
              coalesce(binding.members, []),
              [
                for key in coalesce(binding.member_keys, []) :
                local.service_account_alias_to_email[key]
                if contains(keys(local.service_account_alias_to_email), key)
              ]
            )
            : []
          )
        ]))
      } : {}

      # Transform member objects to additive IAM member entries.
      project_iam_members = var.iam.project_iam_members != null ? {
        for member_key, member_obj in var.iam.project_iam_members :
        member_key => merge(
          {
            role = member_obj.role_key != null ? (
              contains(keys(local.custom_role_alias_to_id), member_obj.role_key)
              ? "projects/${var.iam.project_id}/roles/${local.custom_role_alias_to_id[member_obj.role_key]}"
              : member_obj.role_key
              ) : (
              member_obj.role != null && contains(keys(local.custom_role_alias_to_id), member_obj.role)
              ? "projects/${var.iam.project_id}/roles/${local.custom_role_alias_to_id[member_obj.role]}"
              : member_obj.role
            )
            member = member_obj.member_key != null ? (
              contains(keys(local.service_account_alias_to_email), member_obj.member_key)
              ? local.service_account_alias_to_email[member_obj.member_key]
              : member_obj.member_key
            ) : member_obj.member
          },
          member_obj.condition != null ? {
            condition = {
              title       = member_obj.condition.title
              description = coalesce(member_obj.condition.description, "")
              expression  = member_obj.condition.expression
            }
          } : {}
        )
      } : {}

      # Convert to upstream map(role => members) shape.
      organization_iam_bindings = var.iam.organization_iam_bindings != null ? {
        for _, binding in var.iam.organization_iam_bindings :
        binding.role => binding.members
      } : {}

      # Convert folder field name to upstream folder_id.
      folder_iam_bindings = var.iam.folder_iam_bindings != null ? {
        for key, binding in var.iam.folder_iam_bindings :
        key => {
          folder_id = binding.folder
          role      = binding.role
          members   = binding.members
        }
      } : {}

      # Upstream module indexes condition map by every binding role key.
      # Populate all role keys to avoid invalid index errors when a binding has no condition.
      iam_binding_conditions = var.iam.project_iam_bindings != null ? {
        for resolved_role in distinct([
          for _, binding in var.iam.project_iam_bindings : (
            binding.role_key != null ? (
              contains(keys(local.custom_role_alias_to_id), binding.role_key)
              ? "projects/${var.iam.project_id}/roles/${local.custom_role_alias_to_id[binding.role_key]}"
              : binding.role_key
              ) : (
              binding.role != null && contains(keys(local.custom_role_alias_to_id), binding.role)
              ? "projects/${var.iam.project_id}/roles/${local.custom_role_alias_to_id[binding.role]}"
              : binding.role
            )
          )
          if(
            binding.role_key != null ? binding.role_key : binding.role
          ) != null
        ]) :
        resolved_role => {
          title       = "default_allow_all"
          description = "Compatibility condition for upstream IAM module"
          expression  = "true"
        }
      } : {}

      service_account_iam_bindings = var.iam.service_account_iam_bindings != null ? {
        for key, binding in var.iam.service_account_iam_bindings :
        key => {
          service_account_key = contains(keys(local.service_account_alias_to_account_id), binding.service_account_key) ? local.service_account_alias_to_account_id[binding.service_account_key] : binding.service_account_key
          role                = binding.role
          members             = binding.members
        }
      } : {}

      create_service_account_keys = var.iam.create_service_account_keys != null ? {
        for key, cfg in var.iam.create_service_account_keys :
        (contains(keys(local.service_account_alias_to_account_id), key) ? local.service_account_alias_to_account_id[key] : key) => cfg
      } : {}
    }
  )

  # Ensure IAM is applied after org resources are created
  # depends_on = [module.org]
}
