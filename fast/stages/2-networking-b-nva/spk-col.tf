/**
 * Copyright 2022 Google LLC
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

# tfdoc:file:description Development spoke VPC and related resources.

module "col-spk-prj" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "prj-spk-net-col-001"
  parent          = var.folder_ids.networking-col
  prefix          = "gcp"
  service_config = {
    disable_on_destroy         = false
    disable_dependent_services = false
  }
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "networkmanagement.googleapis.com",
    "servicenetworking.googleapis.com",
    "stackdriver.googleapis.com",
    "dataproc.googleapis.com",
    "recommender.googleapis.com"
  ]
  shared_vpc_host_config = {
    enabled          = true
    service_projects = []
  }
  metric_scopes = [module.hub-prj.project_id]
  iam = {
    "roles/dns.admin" = compact([
      try(local.service_accounts.project-factory-col, null),
      try("serviceAccount:gcp-sva-ocp-srv-col-001@gcp-prj-ocp-srv-col-001.iam.gserviceaccount.com", null)
    ])
    "organizations/1099297987329/roles/dnsRecordsOperator" = compact([
      try("serviceAccount:gcp-sva-kfk-srv-col-001@gcp-prj-kfk-srv-col-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-mdb-srv-col-001@gcp-prj-mdb-srv-col-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-ocp-srv-col-001@gcp-prj-ocp-srv-col-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-sql-srv-col-001@gcp-prj-sql-srv-col-001.iam.gserviceaccount.com", null)
    ])
    "roles/compute.securityAdmin" = compact([
      try("serviceAccount:gcp-sva-ocp-srv-col-001@gcp-prj-ocp-srv-col-001.iam.gserviceaccount.com")
    ])
    "roles/resourcemanager.projectIamAdmin" = compact([
      try("serviceAccount:gcp-sva-ocp-srv-col-001@gcp-prj-ocp-srv-col-001.iam.gserviceaccount.com")
    ])
  }
}

module "col-spk-vpc" {
  source                          = "../../../modules/net-vpc"
  project_id                      = module.col-spk-prj.project_id
  name                            = "gcp-vpc-spk-net-col-001"
  mtu                             = 1500
  data_folder                     = "${var.data_dir}/subnets/col"
  delete_default_routes_on_create = true
  psa_config                      = try(var.psa_ranges.col, null)
  # Set explicit routes for googleapis since default routes are deleted.
  routes = {
    private-googleapis = {
      dest_range    = "199.36.153.8/30"
      priority      = 999
      tags          = []
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
    restricted-googleapis = {
      dest_range    = "199.36.153.4/30"
      priority      = 999
      tags          = []
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
    win-kms-license = {
      dest_range    = "35.190.247.13/32"
      priority      = 100
      tags          = []
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
  }
  subnets_psc = [
    {
      ip_cidr_range = "172.26.63.240/28"
      name          = "gcp-sub-spk-psc-col-ew8-001"
      region        = "europe-west8"
    }
  ]
}

module "col-spk-fw" {
  source              = "../../../modules/net-vpc-firewall"
  project_id          = module.col-spk-prj.project_id
  network             = module.col-spk-vpc.name
  admin_ranges        = []
  http_source_ranges  = []
  https_source_ranges = []
  ssh_source_ranges   = []
  data_folder         = "${var.data_dir}/firewall-rules/col"
  cidr_template_file  = "${var.data_dir}/cidrs.yaml"
}

# Create delegated grants for stage3 service accounts
resource "google_project_iam_binding" "col_spk_prj_iam_delegated" {
  project = module.col-spk-prj.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  members = [try(local.service_accounts.project-factory-col, null)]
  condition {
    title       = "col_stage3_sa_delegated_grants"
    description = "Development host project delegated grants."
    expression = format(
      "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
      join(",", formatlist("'%s'", local.stage3_sas_delegated_grants))
    )
  }
}

### PSC CloudSQL ###
resource "google_compute_global_address" "sql_private_ip_alloc_col" {
  provider      = google-beta
  project       = module.col-spk-prj.name
  name          = "sql-peering-ip-pool-col"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  address       = "172.26.62.0" 
  network       = module.col-spk-vpc.network.id
}

# Create a private connection
resource "google_service_networking_connection" "default_col" {
  network                 = module.col-spk-vpc.network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    google_compute_global_address.sql_private_ip_alloc_col.name,
    ]
}