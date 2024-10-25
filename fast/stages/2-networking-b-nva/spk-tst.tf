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

# tfdoc:file:description Production spoke VPC and related resources.

module "tst-spk-prj" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "prj-spk-net-tst-001"
  parent          = var.folder_ids.networking-tst
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
      try(local.service_accounts.project-factory-tst, null),
      try("serviceAccount:gcp-sva-ocp-srv-tst-001@gcp-prj-ocp-srv-tst-001.iam.gserviceaccount.com", null)
    ])
    "organizations/1099297987329/roles/dnsRecordsOperator" = compact([
      try("serviceAccount:gcp-sva-kfk-srv-tst-001@gcp-prj-kfk-srv-tst-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-mdb-srv-tst-001@gcp-prj-mdb-srv-tst-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-ocp-srv-tst-001@gcp-prj-ocp-srv-tst-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-gke-srv-tst-001@gcp-prj-gke-srv-tst-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-sql-srv-tst-001@gcp-prj-sql-srv-tst-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-lin-srv-tst-001@gcp-prj-lin-srv-tst-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-iac-rmn-shr-001@gcp-prj-org-iac-cor-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-shr-srv-tst-001@gcp-prj-shr-srv-tst-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-shr-ctx-tst-001@gcp-prj-shr-ctx-tst-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-dwh-srv-tst-019@gcp-prj-dwh-srv-tst-019.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-dwh-com-tst-001@gcp-prj-dwh-com-tst-001.iam.gserviceaccount.com", null),
    ])
    "roles/compute.networkViewer" = compact([
      try("serviceAccount:ocp-tst-tjvxr-m@gcp-prj-ocp-srv-tst-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-shr-das-tst-001@gcp-prj-sec-srv-tst-001.iam.gserviceaccount.com", null),
      try("serviceAccount:957416106940@cloudbuild.gserviceaccount.com", null)
    ])
    "roles/compute.securityAdmin" = compact([
      try("serviceAccount:gcp-sva-ocp-srv-tst-001@gcp-prj-ocp-srv-tst-001.iam.gserviceaccount.com")
    ])
    "roles/resourcemanager.projectIamAdmin" = compact([
      try("serviceAccount:gcp-sva-ocp-srv-tst-001@gcp-prj-ocp-srv-tst-001.iam.gserviceaccount.com")
    ])
  }
  iam_additive = {
    "roles/compute.networkUser" = [
      try("serviceAccount:gcp-sva-apg-srv-tst-001@gcp-prj-apg-srv-tst-001.iam.gserviceaccount.com")
    ]
  }
}

module "tst-spk-vpc" {
  source                          = "../../../modules/net-vpc"
  project_id                      = module.tst-spk-prj.project_id
  name                            = "gcp-vpc-spk-net-tst-001"
  mtu                             = 1500
  data_folder                     = "${var.data_dir}/subnets/tst"
  delete_default_routes_on_create = true
  psa_config                      = try(var.psa_ranges.tst, null)
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
  subnets_proxy_only = [
    {
      ip_cidr_range = "172.26.73.0/24"
      name          = "gcp-sub-spk-prx-tst-ew8-001"
      region        = "europe-west8"
      active        = true
      private_ip_google_access = true
    }
  ]
}

module "tst-spk-fw" {
  source              = "../../../modules/net-vpc-firewall"
  project_id          = module.tst-spk-prj.project_id
  network             = module.tst-spk-vpc.name
  admin_ranges        = []
  http_source_ranges  = []
  https_source_ranges = []
  ssh_source_ranges   = []
  data_folder         = "${var.data_dir}/firewall-rules/tst"
  cidr_template_file  = "${var.data_dir}/cidrs.yaml"
}

# Create delegated grants for stage3 service accounts
resource "google_project_iam_binding" "tst_spk_prj_iam_delegated" {
  project = module.tst-spk-prj.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  members = [try(local.service_accounts.project-factory-tst, null)]
  condition {
    title       = "tst_stage3_sa_delegated_grants"
    description = "Production host project delegated grants."
    expression = format(
      "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
      join(",", formatlist("'%s'", local.stage3_sas_delegated_grants))
    )
  }
}


### PSC CloudSQL ###
resource "google_compute_global_address" "private_ip_alloc" {
  provider      = google-beta
  project       = module.tst-spk-prj.name
  name          = "psc-ip-pool-tst"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  address       = "172.26.94.0" 
  network       = module.tst-spk-vpc.network.id
}

### Finastra filestore ###
resource "google_compute_global_address" "private_ip_alloc_filestore" {
  provider      = google-beta
  project       = module.tst-spk-prj.name
  name          = "psc-filestore-ip-pool-tst"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  address       = "172.26.93.0" 
  network       = module.tst-spk-vpc.network.id
}

### Apigee ###

resource "google_compute_global_address" "private_ip_alloc_apigee" {
  provider      = google-beta
  project       = module.tst-spk-prj.name
  name          = "psc-apigee-ip-pool-tst"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 22
  address       = "172.26.88.0" 
  network       = module.tst-spk-vpc.network.id
}

resource "google_compute_global_address" "private_ip_alloc_apigee2" {
  provider      = google-beta
  project       = module.tst-spk-prj.name
  name          = "psc-apigee-ip-pool-tst-2"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 28
  address       = "172.26.95.16" 
  network       = module.tst-spk-vpc.network.id
}

resource "google_service_networking_peered_dns_domain" "apigee-dns-secservizi-sec" {
  project    = module.tst-spk-prj.name
  name       = "apigee-tst-dns-peering-secservizi-sec"
  network    = module.tst-spk-vpc.network.name
  dns_suffix = "secservizi.sec."
}

# Create a private connection
resource "google_service_networking_connection" "default" {
  network                 = module.tst-spk-vpc.network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    google_compute_global_address.private_ip_alloc.name,
    google_compute_global_address.private_ip_alloc_filestore.name,
    google_compute_global_address.private_ip_alloc_apigee.name,
    google_compute_global_address.private_ip_alloc_apigee2.name
    ]
}

resource "google_compute_network_peering_routes_config" "peering_routes_default_tst" {
  project = module.tst-spk-prj.name
  peering = google_service_networking_connection.default.peering
  network = module.tst-spk-vpc.network.name

  import_custom_routes = true
  export_custom_routes = true
}
