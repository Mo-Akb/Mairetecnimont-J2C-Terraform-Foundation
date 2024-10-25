module "branch-maire-folder" {
  source = "../../../modules/folder"
  parent = local.root_node
  name   = "maire-fldr"
  # iam_by_principals = {
  #   (local.principals.gcp-network-admins) = [
  #     # owner and viewer roles are broad and might grant unwanted access
  #     # replace them with more selective custom roles for production deployments
  #     "roles/editor",
  #   ]
  # }
  # iam = local._network_folder_iam
  # tag_bindings = {
  #   context = try(
  #     local.tag_values["${var.tag_names.context}/maire"].id, null
  #   )
  # }
}