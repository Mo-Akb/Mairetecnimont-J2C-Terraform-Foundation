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

module "prd-spk-prj" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "prj-spk-net-prd-001"
  parent          = var.folder_ids.networking-prd
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
      try(local.service_accounts.project-factory-prd, null),
      try("serviceAccount:gcp-sva-ocp-srv-prd-001@gcp-prj-ocp-srv-prd-001.iam.gserviceaccount.com", null),
    ])
    "organizations/1099297987329/roles/dnsRecordsOperator" = compact([
      try("serviceAccount:gcp-sva-kfk-srv-prd-001@gcp-prj-kfk-srv-prd-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-mdb-srv-prd-001@gcp-prj-mdb-srv-prd-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-ocp-srv-prd-001@gcp-prj-ocp-srv-prd-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-iac-rmn-shr-001@gcp-prj-org-iac-cor-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-shr-srv-prd-001@gcp-prj-shr-srv-prd-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-lin-srv-prd-001@gcp-prj-lin-srv-prd-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-gke-srv-prd-001@gcp-prj-gke-srv-prd-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-sql-srv-prd-001@gcp-prj-sql-srv-prd-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-shr-ctx-prd-001@gcp-prj-shr-ctx-prd-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-dwh-srv-prd-019@gcp-prj-dwh-srv-prd-019.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-dwh-com-prd-001@gcp-prj-dwh-com-prd-001.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-dwh-srv-prd-068@gcp-prj-dwh-srv-prd-068.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-dwh-srv-prd-038@gcp-prj-dwh-srv-prd-038.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-dwh-srv-prd-080@gcp-prj-dwh-srv-prd-080.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-dwh-srv-prd-082@gcp-prj-dwh-srv-prd-082.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-dwh-srv-prd-029@gcp-prj-dwh-srv-prd-029.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-dwh-srv-prd-052@gcp-prj-dwh-srv-prd-052.iam.gserviceaccount.com", null),
      try("serviceAccount:gcp-sva-dwh-srv-prd-012@gcp-prj-dwh-srv-prd-012.iam.gserviceaccount.com", null),
    ])
    "roles/compute.networkViewer" = compact([
      try("serviceAccount:gcp-sva-shr-das-prd-001@gcp-prj-sec-srv-prd-001.iam.gserviceaccount.com"),
      try("serviceAccount:492858916500@cloudbuild.gserviceaccount.com"),
      try("serviceAccount:ocp-prd-f5ckt-m@gcp-prj-ocp-srv-prd-001.iam.gserviceaccount.com")
    ])
    "roles/compute.securityAdmin" = compact([
      try("serviceAccount:gcp-sva-ocp-srv-prd-001@gcp-prj-ocp-srv-prd-001.iam.gserviceaccount.com")
    ])
    "roles/resourcemanager.projectIamAdmin" = compact([
      try("serviceAccount:gcp-sva-ocp-srv-prd-001@gcp-prj-ocp-srv-prd-001.iam.gserviceaccount.com")
    ])
  }
  iam_additive = {
    "roles/compute.networkUser" = [
      try("serviceAccount:gcp-sva-apg-srv-prd-001@gcp-prj-apg-srv-prd-001.iam.gserviceaccount.com")
    ]
  }
}

module "prd-spk-vpc" {
  source                          = "../../../modules/net-vpc"
  project_id                      = module.prd-spk-prj.project_id
  name                            = "gcp-vpc-spk-net-prd-001"
  mtu                             = 1500
  data_folder                     = "${var.data_dir}/subnets/prd"
  delete_default_routes_on_create = true
  psa_config                      = try(var.psa_ranges.prd, null)
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
      ip_cidr_range = "172.26.10.0/24"
      name          = "gcp-sub-spk-prx-prd-ew8-001"
      region        = "europe-west8"
      active        = true
      private_ip_google_access = true
    }
  ]
}

module "prd-spk-fw" {
  source              = "../../../modules/net-vpc-firewall"
  project_id          = module.prd-spk-prj.project_id
  network             = module.prd-spk-vpc.name
  admin_ranges        = []
  http_source_ranges  = []
  https_source_ranges = []
  ssh_source_ranges   = []
  data_folder         = "${var.data_dir}/firewall-rules/prd"
  cidr_template_file  = "${var.data_dir}/cidrs.yaml"
}

# Create delegated grants for stage3 service accounts
resource "google_project_iam_binding" "prd_spk_prj_iam_delegated" {
  project = module.prd-spk-prj.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  members = [try(local.service_accounts.project-factory-prd, null)]
  condition {
    title       = "prd_stage3_sa_delegated_grants"
    description = "Production host project delegated grants."
    expression = format(
      "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
      join(",", formatlist("'%s'", local.stage3_sas_delegated_grants))
    )
  }
}

resource "google_compute_global_address" "private_ip_alloc_filestore_prd" {
  provider      = google-beta
  project       = module.prd-spk-prj.name
  name          = "psc-filestore-ip-pool-prd"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  address       = "172.26.29.0" 
  network       = module.prd-spk-vpc.network.id
}

### PSC CloudSQL ###
resource "google_compute_global_address" "sql_private_ip_alloc_prd" {
  provider      = google-beta
  project       = module.prd-spk-prj.name
  name          = "sql-peering-ip-pool-prd"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  address       = "172.26.30.0" 
  network       = module.prd-spk-vpc.network.id
}

### Apigee ###

resource "google_compute_global_address" "private_ip_alloc_apigee_prod" {
  provider      = google-beta
  project       = module.prd-spk-prj.name
  name          = "psc-apigee-ip-pool-prd"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 22
  address       = "172.26.24.0" 
  network       = module.prd-spk-vpc.network.id
}

resource "google_compute_global_address" "private_ip_alloc_apigee2_prod" {
  provider      = google-beta
  project       = module.prd-spk-prj.name
  name          = "psc-apigee-ip-pool-prd-2"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 28
  address       = "172.26.31.224" 
  network       = module.prd-spk-vpc.network.id
}

resource "google_service_networking_connection" "service_networking_prd" {
  network                 = module.prd-spk-vpc.network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    google_compute_global_address.private_ip_alloc_filestore_prd.name,
    google_compute_global_address.sql_private_ip_alloc_prd.name,
    google_compute_global_address.private_ip_alloc_apigee_prod.name,
    google_compute_global_address.private_ip_alloc_apigee2_prod.name
    ]
}

resource "google_compute_network_peering_routes_config" "peering_routes_default_prd" {
  project = module.prd-spk-prj.name
  peering = google_service_networking_connection.service_networking_prd.peering
  network = module.prd-spk-vpc.network.name

  import_custom_routes = true
  export_custom_routes = true
}

resource "google_service_networking_peered_dns_domain" "apigee-dns-secservizi-sec-prd" {
  project    = module.prd-spk-prj.name
  name       = "apigee-prd-dns-peering-secservizi-sec"
  network    = module.prd-spk-vpc.network.name
  dns_suffix = "secservizi.sec."
}

resource "google_service_networking_peered_dns_domain" "apigee-dns-seccloud-internal-prd" {
  project    = module.prd-spk-prj.name
  name       = "apigee-prd-dns-peering-seccloud-internal"
  network    = module.prd-spk-vpc.network.name
  dns_suffix = "seccloud.internal."
}