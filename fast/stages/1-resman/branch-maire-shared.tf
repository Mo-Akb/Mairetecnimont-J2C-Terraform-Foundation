/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# tfdoc:file:description Networking stage resources.

locals {
  # FAST-specific IAM
  _network_folder_fast_iam = merge(
    {
      # read-write (apply) automation service account
      "roles/logging.admin"                  = [module.branch-network-sa.iam_email]
      "roles/owner"                          = [module.branch-network-sa.iam_email]
      "roles/resourcemanager.folderAdmin"    = [module.branch-network-sa.iam_email]
      "roles/resourcemanager.projectCreator" = [module.branch-network-sa.iam_email]
      "roles/compute.xpnAdmin"               = [module.branch-network-sa.iam_email]
      # read-only (plan) automation service account
      "roles/viewer"                       = [module.branch-network-r-sa.iam_email]
      "roles/resourcemanager.folderViewer" = [module.branch-network-r-sa.iam_email]
    },
    var.fast_features.nsec != true ? {} : {
      # nsec service accounts
      "roles/serviceusage.serviceUsageAdmin" = [
        try(module.branch-nsec-sa[0].iam_email, null)
      ]
      "roles/serviceusage.serviceUsageConsumer" = [
        try(module.branch-nsec-r-sa[0].iam_email, null)
      ]
      (var.custom_roles["network_firewall_policies_admin"]) = [
        try(module.branch-nsec-sa[0].iam_email, null)
      ]
      "roles/compute.orgFirewallPolicyUser" = [
        try(module.branch-nsec-r-sa[0].iam_email, null)
      ]
    }
  )
  # deep-merge FAST-specific IAM with user-provided bindings in var.folder_iam
  _network_folder_iam = merge(
    var.folder_iam.network,
    {
      for role, principals in local._network_folder_fast_iam :
      role => distinct(concat(principals, lookup(var.folder_iam.network, role, [])))
    }
  )
}

module "branch-maire-shared-folder" {
  source = "../../../modules/folder"
  parent = local.root_node
  name   = "maire-shared-fldr"
  iam_by_principals = {
    (local.principals.gcp-network-admins) = [
      # owner and viewer roles are broad and might grant unwanted access
      # replace them with more selective custom roles for production deployments
      "roles/editor",
    ]
  }
  iam = local._network_folder_iam
  tag_bindings = {
    context = try(
      local.tag_values["${var.tag_names.context}/networking"].id, null
    )
  }
}

module "branch-maire-billing-folder" {
  source = "../../../modules/folder"
  parent = module.branch-maire-shared-folder.id
  name   = "maire-billing-fldr"
  iam = {
    # read-write (apply) automation service accounts
    (local.custom_roles.service_project_network_admin) = compact([
      try(module.branch-dp-prod-sa[0].iam_email, null),
      try(module.branch-gcve-prod-sa[0].iam_email, null),
      try(module.branch-gke-prod-sa[0].iam_email, null),
      try(module.branch-pf-sa.iam_email, null),
      try(module.branch-pf-prod-sa.iam_email, null)
    ])
    # read-only (plan) automation service accounts
    "roles/compute.networkViewer" = compact([
      try(module.branch-dp-prod-r-sa[0].iam_email, null),
      try(module.branch-gcve-prod-r-sa[0].iam_email, null),
      try(module.branch-gke-prod-r-sa[0].iam_email, null),
      try(module.branch-pf-r-sa.iam_email, null),
      try(module.branch-pf-prod-r-sa.iam_email, null)
    ])
    (local.custom_roles.gcve_network_admin) = compact([
      try(module.branch-gcve-prod-sa[0].iam_email, null)
    ])
  }
  tag_bindings = {
    environment = try(
      local.tag_values["${var.tag_names.environment}/production"].id,
      null
    )
  }
}

module "branch-maire-networking-folder" {
  source = "../../../modules/folder"
  parent = module.branch-maire-shared-folder.id
  name   = "maire-networking-fldr"
  iam = {
    # read-write (apply) automation service accounts
    (local.custom_roles.service_project_network_admin) = compact([
      try(module.branch-dp-dev-sa[0].iam_email, null),
      try(module.branch-gcve-dev-sa[0].iam_email, null),
      try(module.branch-gke-dev-sa[0].iam_email, null),
      try(module.branch-pf-sa.iam_email, null),
      try(module.branch-pf-dev-sa.iam_email, null)
    ])
    # read-only (plan) automation service accounts
    "roles/compute.networkViewer" = compact([
      try(module.branch-dp-dev-r-sa[0].iam_email, null),
      try(module.branch-gcve-dev-r-sa[0].iam_email, null),
      try(module.branch-gke-dev-r-sa[0].iam_email, null),
      try(module.branch-pf-r-sa.iam_email, null),
      try(module.branch-pf-dev-r-sa.iam_email, null)
    ])
    (local.custom_roles.gcve_network_admin) = compact([
      try(module.branch-gcve-dev-sa[0].iam_email, null)
    ])
  }
  tag_bindings = {
    environment = try(
      local.tag_values["${var.tag_names.environment}/development"].id,
      null
    )
  }
}

module "branch-maire-logging-folder" {
  source = "../../../modules/folder"
  parent = module.branch-maire-shared-folder.id
  name   = "maire-logging-fldr"
  iam = {
    # read-write (apply) automation service accounts
    (local.custom_roles.service_project_network_admin) = compact([
      try(module.branch-dp-dev-sa[0].iam_email, null),
      try(module.branch-gcve-dev-sa[0].iam_email, null),
      try(module.branch-gke-dev-sa[0].iam_email, null),
      try(module.branch-pf-sa.iam_email, null),
      try(module.branch-pf-dev-sa.iam_email, null)
    ])
    # read-only (plan) automation service accounts
    "roles/compute.networkViewer" = compact([
      try(module.branch-dp-dev-r-sa[0].iam_email, null),
      try(module.branch-gcve-dev-r-sa[0].iam_email, null),
      try(module.branch-gke-dev-r-sa[0].iam_email, null),
      try(module.branch-pf-r-sa.iam_email, null),
      try(module.branch-pf-dev-r-sa.iam_email, null)
    ])
    (local.custom_roles.gcve_network_admin) = compact([
      try(module.branch-gcve-dev-sa[0].iam_email, null)
    ])
  }
  tag_bindings = {
    environment = try(
      local.tag_values["${var.tag_names.environment}/development"].id,
      null
    )
  }
}

module "branch-maire-security-folder" {
  source = "../../../modules/folder"
  parent = module.branch-maire-shared-folder.id
  name   = "maire-security-fldr"
  iam = {
    # read-write (apply) automation service accounts
    (local.custom_roles.service_project_network_admin) = compact([
      try(module.branch-dp-dev-sa[0].iam_email, null),
      try(module.branch-gcve-dev-sa[0].iam_email, null),
      try(module.branch-gke-dev-sa[0].iam_email, null),
      try(module.branch-pf-sa.iam_email, null),
      try(module.branch-pf-dev-sa.iam_email, null)
    ])
    # read-only (plan) automation service accounts
    "roles/compute.networkViewer" = compact([
      try(module.branch-dp-dev-r-sa[0].iam_email, null),
      try(module.branch-gcve-dev-r-sa[0].iam_email, null),
      try(module.branch-gke-dev-r-sa[0].iam_email, null),
      try(module.branch-pf-r-sa.iam_email, null),
      try(module.branch-pf-dev-r-sa.iam_email, null)
    ])
    (local.custom_roles.gcve_network_admin) = compact([
      try(module.branch-gcve-dev-sa[0].iam_email, null)
    ])
  }
  tag_bindings = {
    environment = try(
      local.tag_values["${var.tag_names.environment}/development"].id,
      null
    )
  }
}

# automation service account

module "branch-network-sa" {
  source                 = "../../../modules/iam-service-account"
  project_id             = var.automation.project_id
  name                   = "prod-resman-net-0"
  display_name           = "Terraform resman networking service account."
  prefix                 = var.prefix
  service_account_create = var.root_node == null
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-network-sa-cicd[0].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

# automation read-only service account

module "branch-network-r-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = var.automation.project_id
  name         = "prod-resman-net-0r"
  display_name = "Terraform resman networking service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-network-r-sa-cicd[0].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = [var.custom_roles["storage_viewer"]]
  }
}

# automation bucket

module "branch-network-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation.project_id
  name       = "prod-resman-net-0"
  prefix     = var.prefix
  location   = var.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin"  = [module.branch-network-sa.iam_email]
    "roles/storage.objectViewer" = [module.branch-network-r-sa.iam_email]
  }
}