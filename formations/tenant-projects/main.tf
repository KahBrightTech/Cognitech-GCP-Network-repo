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
module "iam" {
  source = "git::https://github.com/KahBrightTech/Cognitech-GCP-Infrastructure-Manager-repo.git//Infrastructure-Manger/modules/IAM?ref=v1.0.0"

  iam = merge(
    var.iam,
    {
      # Transform project_iam_bindings to resolve key references
      project_iam_bindings = var.iam.project_iam_bindings != null ? {
        for binding_key, binding in var.iam.project_iam_bindings :
        binding_key => merge(
          binding,
          {
            # Resolve role: use role_key if provided, otherwise check if role is a custom role key
            role = binding.role_key != null ? (
              var.iam.custom_roles != null && contains([for k, r in var.iam.custom_roles : coalesce(r.key, k)], binding.role_key)
              ? "projects/${var.iam.project_id}/roles/${[for k, r in var.iam.custom_roles : r.role_id if coalesce(r.key, k) == binding.role_key][0]}"
              : binding.role_key
              ) : (
              binding.role != null && var.iam.custom_roles != null && contains([for k, r in var.iam.custom_roles : coalesce(r.key, k)], binding.role)
              ? "projects/${var.iam.project_id}/roles/${[for k, r in var.iam.custom_roles : r.role_id if coalesce(r.key, k) == binding.role][0]}"
              : binding.role
            )
            # Resolve members: combine members list with resolved member_keys
            members = concat(
              coalesce(binding.members, []),
              var.iam.service_accounts != null && binding.member_keys != null ? [
                for key in binding.member_keys :
                "serviceAccount:${[for k, sa in var.iam.service_accounts : sa.account_id if coalesce(sa.key, k) == key][0]}@${coalesce([for k, sa in var.iam.service_accounts : sa.project_id if coalesce(sa.key, k) == key][0], var.iam.project_id)}.iam.gserviceaccount.com"
                if var.iam.service_accounts != null && contains([for k, sa in var.iam.service_accounts : coalesce(sa.key, k)], key)
              ] : []
            )
          }
        )
      } : {}

      # Transform project_iam_members to resolve key references
      project_iam_members = var.iam.project_iam_members != null ? {
        for member_key, member_obj in var.iam.project_iam_members :
        member_key => merge(
          member_obj,
          {
            # Resolve role: use role_key if provided, otherwise check if role is a custom role key
            role = member_obj.role_key != null ? (
              var.iam.custom_roles != null && contains([for k, r in var.iam.custom_roles : coalesce(r.key, k)], member_obj.role_key)
              ? "projects/${var.iam.project_id}/roles/${[for k, r in var.iam.custom_roles : r.role_id if coalesce(r.key, k) == member_obj.role_key][0]}"
              : member_obj.role_key
              ) : (
              member_obj.role != null && var.iam.custom_roles != null && contains([for k, r in var.iam.custom_roles : coalesce(r.key, k)], member_obj.role)
              ? "projects/${var.iam.project_id}/roles/${[for k, r in var.iam.custom_roles : r.role_id if coalesce(r.key, k) == member_obj.role][0]}"
              : member_obj.role
            )
            # Resolve member: use member_key if provided, otherwise use member
            member = member_obj.member_key != null ? (
              var.iam.service_accounts != null && contains([for k, sa in var.iam.service_accounts : coalesce(sa.key, k)], member_obj.member_key)
              ? "serviceAccount:${[for k, sa in var.iam.service_accounts : sa.account_id if coalesce(sa.key, k) == member_obj.member_key][0]}@${coalesce([for k, sa in var.iam.service_accounts : sa.project_id if coalesce(sa.key, k) == member_obj.member_key][0], var.iam.project_id)}.iam.gserviceaccount.com"
              : member_obj.member_key
            ) : member_obj.member
          }
        )
      } : {}
    }
  )

  # Ensure IAM is applied after org resources are created
  # depends_on = [module.org]
}
