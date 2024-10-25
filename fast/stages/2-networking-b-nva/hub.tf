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

# tfdoc:file:description Landing VPC and related resources.

module "hub-prj" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "gcp-prj-hub-net-cor-001"
  parent          = var.folder_ids.networking-prd
  prefix          = null
  skip_delete = true
  service_config = {
    disable_on_destroy         = false
    disable_dependent_services = false
  }
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "networkmanagement.googleapis.com",
    "stackdriver.googleapis.com",
    "dataproc.googleapis.com",
    "recommender.googleapis.com",
    "serviceusage.googleapis.com"
  ]
  shared_vpc_host_config = {
    enabled          = true
    service_projects = []
  }
  iam = {
    "roles/dns.admin" = compact([
      try(local.service_accounts.project-factory-prd, null)
    ])
    (local.custom_roles.service_project_network_admin) = compact([
      try(local.service_accounts.project-factory-prd, null)
    ])
  }
}

# External\Untrusted VPC

module "hub-ext-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.hub-prj.project_id
  name       = "gcp-vpc-hub-net-cor-001"
  delete_default_routes_on_create = true
  mtu        = 1500
  
  # Set explicit routes for googleapis in case the default route is deleted
  routes = {
    private-googleapis = {
      dest_range    = "199.36.153.8/30"
      priority      = 1000
      tags          = []
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
    restricted-googleapis = {
      dest_range    = "199.36.153.4/30"
      priority      = 1000
      tags          = []
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
    to-spokes = {
      dest_range    = "172.26.0.0/16"
      priority      = 1001
      tags          = []
      next_hop_type = "ilb"
      next_hop      = google_compute_forwarding_rule.hub_ilb_ext_fwd_rule.ip_address
    }
    to-internet = {
      dest_range    = "0.0.0.0/0"
      priority      = 500
      tags          = []
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
    to-hub-fw-mgmt = {
      dest_range    = "172.26.255.64/28"
      priority      = 400
      tags          = []
      next_hop_type = "ilb"
      next_hop      = google_compute_forwarding_rule.lnd_ilb_int_fwd_rule.ip_address
    }
  }
  
  dns_policy = {
    inbound  = false
    logging  = false
    outbound = null
  }

  data_folder = "${var.data_dir}/subnets/hub-ext"
}

module "hub-ext-fw" {
  source              = "../../../modules/net-vpc-firewall"
  project_id          = module.hub-prj.project_id
  network             = module.hub-ext-vpc.name
  admin_ranges        = []
  http_source_ranges  = []
  https_source_ranges = []
  ssh_source_ranges   = []
  data_folder         = "${var.data_dir}/firewall-rules/hub-ext"
  cidr_template_file  = "${var.data_dir}/cidrs.yaml"
}

# NAT
#34.154.242.17
resource "google_compute_address" "nat_hub_pub" {
  project                = module.hub-prj.project_id 
  name                   = "gcp-ip4-hub-nat-ext-${var.region_trigram}-001"
  region                 = var.region
  address_type           = "EXTERNAL"
}

module "hub-ext-nat-ew8" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.hub-prj.project_id
  region         = "europe-west8"
  name           = "gcp-nat-hub-net-cor-ew8-001"
  router_create  = true
  router_name    = "gcp-rtr-hub-net-cor-ew8-001"
  router_network = module.hub-ext-vpc.name
  router_asn     = 4200001024
  addresses = [google_compute_address.nat_hub_pub.name]
  config_min_ports_per_vm = 1024
  enable_endpoint_independent_mapping = false
  config_source_subnets = "LIST_OF_SUBNETWORKS"
  subnetworks = [
    {
      self_link                = module.hub-ext-vpc.subnet_self_links["europe-west8/gcp-sub-hub-ext-cor-ew8-001"]
      config_source_ranges     = ["ALL_IP_RANGES"]
      secondary_ranges         = null
    }
  ]
}

# Trusted VPC

module "hub-int-vpc" {
  source                          = "../../../modules/net-vpc"
  project_id                      = module.hub-prj.project_id
  name                            = "gcp-vpc-hub-net-cor-002"
  delete_default_routes_on_create = true
  mtu                             = 1500

  # Set explicit routes for googleapis in case the default route is deleted
  routes = {
    private-googleapis = {
      dest_range    = "199.36.153.8/30"
      priority      = 1000
      tags          = []
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
    restricted-googleapis = {
      dest_range    = "199.36.153.4/30"
      priority      = 1000
      tags          = []
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
    to-on-prem = {
      dest_range    = "0.0.0.0/0"
      priority      = 1001
      tags          = []
      next_hop_type = "ilb"
      next_hop      = google_compute_forwarding_rule.hub_ilb_int_fwd_rule.ip_address
    }
  }

  dns_policy = {
    inbound  = true
    logging  = false
    outbound = null
  }

  data_folder = "${var.data_dir}/subnets/hub-int"
}

module "hub-int-fw" {
  source              = "../../../modules/net-vpc-firewall"
  project_id          = module.hub-prj.project_id
  network             = module.hub-int-vpc.name
  admin_ranges        = []
  http_source_ranges  = []
  https_source_ranges = []
  ssh_source_ranges   = []
  data_folder         = "${var.data_dir}/firewall-rules/hub-int"
  cidr_template_file  = "${var.data_dir}/cidrs.yaml"
}
