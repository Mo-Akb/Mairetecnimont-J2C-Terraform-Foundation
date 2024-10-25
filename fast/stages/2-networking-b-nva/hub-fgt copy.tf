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

###############################################
#             ACTIVE-FORTIGATE
###############################################

module "hub-fgt-ew8-active" {
  source         = "../../../modules/compute-vm"
  project_id     = module.hub-prj.project_id
  name           = "gcp-gce-hub-fwl-cor-${var.region_trigram}-001"
  zone           = "${var.region}-a"
  tags           = ["fwl"]
  labels = {
    app = "infra"
    env = "prd"
    "isto_appliances" = "firewall_fortinet"
    mdw = "fortigate"
    project = "sicurezza"
  }
  can_ip_forward = true
  network_interfaces = [
    {
      network    = module.hub-ext-vpc.self_link
      subnetwork = module.hub-ext-vpc.subnet_self_links["europe-west8/gcp-sub-hub-ext-cor-ew8-001"]
      nat        = false
      addresses  = {
        internal = google_compute_address.hub_ext_pvt[0].address
        external = null
      }
    },
    {
      network    = module.hub-int-vpc.self_link
      subnetwork = module.hub-int-vpc.subnet_self_links["europe-west8/gcp-sub-hub-int-cor-ew8-001"]
      nat        = false
      addresses  = {
        internal = google_compute_address.hub_int_pvt[0].address
        external = null
      }
    },
    {
      network    = module.hub-syn-vpc.self_link
      subnetwork = module.hub-syn-vpc.subnet_self_links["europe-west8/gcp-sub-hub-syn-cor-ew8-001"]
      nat        = false
      addresses  = {
        internal = google_compute_address.hub_syn_pvt[0].address
        external = null
      }
    },
    {
      network    = module.hub-mgt-vpc.self_link
      subnetwork = module.hub-mgt-vpc.subnet_self_links["europe-west8/gcp-sub-hub-mgt-cor-ew8-001"]
      nat        = false
      addresses  = {
        internal = google_compute_address.hub_mgt_pvt[0].address
        external = null
      }
    }
  ]
  boot_disk = {
    image = "projects/fortigcp-project-001/global/images/fortinet-fgt-6410-20220829-001-w-license"
    type  = "pd-balanced"
    size  = 50
  }
  create_template = false
  instance_type   = "n2-standard-8"
  options = {
    allow_stopping_for_update = false
    deletion_protection       = true
    spot                      = false
    termination_action        = "STOP"
  }
  metadata = {
    user-data = templatefile("${path.module}/data/hub-fgt-base-config.tftpl", {
    hostname               = "hubfwl1"
    unicast_peer_ip        = google_compute_address.hub_syn_pvt[1].address
    unicast_peer_netmask   = cidrnetmask(local.subnets.gcp-sub-hub-syn-cor-ew8-001-cidr)
    ha_prio                = 1
    healthcheck_port       = var.healthcheck_port
    hub_ext_ip             = google_compute_address.hub_ext_pvt[0].address
    hub_ext_gw             = local.subnets.gcp-sub-hub-ext-cor-ew8-001-gw
    hub_int_ip             = google_compute_address.hub_int_pvt[0].address
    hub_int_gw             = local.subnets.gcp-sub-hub-int-cor-ew8-001-gw
    hub_int_cidr           = local.subnets.gcp-sub-hub-int-cor-ew8-001-cidr
    hub_syn_ip             = google_compute_address.hub_syn_pvt[0].address
    hub_mgt_ip             = google_compute_address.hub_mgt_pvt[0].address
    hub_mgt_gw             = local.subnets.gcp-sub-hub-mgt-cor-ew8-001-gw
    hub_int_ilb_ip         = google_compute_address.hub_ilb_int.address
    hub_ext_ilb_ip         = google_compute_address.hub_ilb_ext.address
    api_acl                = var.api_acl
    })
  }
}

###############################################
#             PASSIVE-FORTIGATE
###############################################

module "hub-fgt-ew8-passive" {
  source         = "../../../modules/compute-vm"
  project_id     = module.hub-prj.project_id
  name           = "gcp-gce-hub-fwl-cor-${var.region_trigram}-002"
  zone           = "${var.region}-c"
  tags           = ["fwl"]
  labels = {
    app = "infra"
    env = "prd"
    "isto_appliances" = "firewall_fortinet"
    mdw = "fortigate"
    project = "sicurezza"
  }
  can_ip_forward = true
  network_interfaces = [
    {
      network    = module.hub-ext-vpc.self_link
      subnetwork = module.hub-ext-vpc.subnet_self_links["europe-west8/gcp-sub-hub-ext-cor-ew8-001"]
      nat        = false
      addresses  = {
        internal = google_compute_address.hub_ext_pvt[1].address
        external = null
      }
    },
    {
      network    = module.hub-int-vpc.self_link
      subnetwork = module.hub-int-vpc.subnet_self_links["europe-west8/gcp-sub-hub-int-cor-ew8-001"]
      nat        = false
      addresses  = {
        internal = google_compute_address.hub_int_pvt[1].address
        external = null
      }
    },
    {
      network    = module.hub-syn-vpc.self_link
      subnetwork = module.hub-syn-vpc.subnet_self_links["europe-west8/gcp-sub-hub-syn-cor-ew8-001"]
      nat        = false
      addresses  = {
        internal = google_compute_address.hub_syn_pvt[1].address
        external = null
      }
    },
    {
      network    = module.hub-mgt-vpc.self_link
      subnetwork = module.hub-mgt-vpc.subnet_self_links["europe-west8/gcp-sub-hub-mgt-cor-ew8-001"]
      nat        = false
      addresses  = {
        internal = google_compute_address.hub_mgt_pvt[1].address
        external = null
      }
    }
  ]
  boot_disk = {
    image = "projects/fortigcp-project-001/global/images/fortinet-fgt-6410-20220829-001-w-license"
    type  = "pd-balanced"
    size  = 50
  }
  create_template = false
  instance_type   = "n2-standard-8"
  options = {
    allow_stopping_for_update = false
    deletion_protection       = true
    spot                      = false
    termination_action        = "STOP"
  }
  metadata = {
    user-data = templatefile("${path.module}/data/hub-fgt-base-config.tftpl", {
    hostname               = "hubfwl2"
    unicast_peer_ip        = google_compute_address.hub_syn_pvt[0].address
    unicast_peer_netmask   = cidrnetmask(local.subnets.gcp-sub-hub-syn-cor-ew8-001-cidr)
    ha_prio                = 0
    healthcheck_port       = var.healthcheck_port
    hub_ext_ip             = google_compute_address.hub_ext_pvt[1].address
    hub_ext_gw             = local.subnets.gcp-sub-hub-ext-cor-ew8-001-gw
    hub_int_ip             = google_compute_address.hub_int_pvt[1].address
    hub_int_gw             = local.subnets.gcp-sub-hub-int-cor-ew8-001-gw
    hub_int_cidr           = local.subnets.gcp-sub-hub-int-cor-ew8-001-cidr
    hub_syn_ip             = google_compute_address.hub_syn_pvt[1].address
    hub_mgt_ip             = google_compute_address.hub_mgt_pvt[1].address
    hub_mgt_gw             = local.subnets.gcp-sub-hub-mgt-cor-ew8-001-gw
    hub_int_ilb_ip         = google_compute_address.hub_ilb_int.address
    hub_ext_ilb_ip         = google_compute_address.hub_ilb_ext.address
    api_acl                = var.api_acl
    })
  }
}

resource "google_compute_instance_group" "hub-fgt-umig-a" {
  name                   = "gcp-uig-hub-fwl-cor-${var.region_trigram}-001"
  project                = module.hub-prj.project_id
  zone                   = "${var.region}-${var.zones[0]}"
  instances              = [module.hub-fgt-ew8-active.self_link]
}

resource "google_compute_instance_group" "hub-fgt-umig-c" {
  name                   = "gcp-uig-hub-fwl-cor-${var.region_trigram}-002"
  project                = module.hub-prj.project_id
  zone                   = "${var.region}-${var.zones[1]}"
  instances              = [module.hub-fgt-ew8-passive.self_link]
}

#Outside backend service
resource "google_compute_region_backend_service" "hub_ilb_ext_bes" {
  provider               = google-beta
  project                = module.hub-prj.project_id
  name                   = "gcp-ilb-hub-fwl-ext-${var.region_trigram}-001"
  region                 = var.region
  network                = module.hub-ext-vpc.name
  load_balancing_scheme  = "INTERNAL"

  backend {
    group                = google_compute_instance_group.hub-fgt-umig-a.self_link
  }
  backend {
    group                = google_compute_instance_group.hub-fgt-umig-c.self_link
  }

  health_checks          = [google_compute_region_health_check.hub_health_check.self_link]
  connection_tracking_policy {
    connection_persistence_on_unhealthy_backends = "NEVER_PERSIST"
  }
}

resource "google_compute_forwarding_rule" "hub_ilb_ext_fwd_rule" {
  name                   = "gcp-ilb-hub-fwd-ext-${var.region_trigram}-001"
  project                = module.hub-prj.project_id
  region                 = var.region
  network                = module.hub-ext-vpc.name
  subnetwork             = module.hub-ext-vpc.subnet_self_links["europe-west8/gcp-sub-hub-ext-cor-ew8-001"]
  ip_address             = google_compute_address.hub_ilb_ext.address
  all_ports              = true
  load_balancing_scheme  = "INTERNAL"
  backend_service        = google_compute_region_backend_service.hub_ilb_ext_bes.self_link
  allow_global_access    = true
}

#Inside backend service
resource "google_compute_region_backend_service" "hub_ilb_int_bes" {
  provider               = google-beta
  project                = module.hub-prj.project_id
  name                   = "gcp-ilb-hub-fwl-int-${var.region_trigram}-001"
  region                 = var.region
  network                = module.hub-int-vpc.name
  load_balancing_scheme  = "INTERNAL"

  backend {
    group                = google_compute_instance_group.hub-fgt-umig-a.self_link
  }
  backend {
    group                = google_compute_instance_group.hub-fgt-umig-c.self_link
  }

  health_checks          = [google_compute_region_health_check.hub_health_check.self_link]
  connection_tracking_policy {
    connection_persistence_on_unhealthy_backends = "NEVER_PERSIST"
  }
  log_config {
    enable = false
    sample_rate = 1
  }
}

resource "google_compute_forwarding_rule" "hub_ilb_int_fwd_rule" {
  name                   = "gcp-ilb-hub-fwd-int-${var.region_trigram}-001"
  project                = module.hub-prj.project_id
  region                 = var.region
  network                = module.hub-int-vpc.name
  subnetwork             = module.hub-int-vpc.subnet_self_links["europe-west8/gcp-sub-hub-int-cor-ew8-001"]
  ip_address             = google_compute_address.hub_ilb_int.address
  all_ports              = true
  load_balancing_scheme  = "INTERNAL"
  backend_service        = google_compute_region_backend_service.hub_ilb_int_bes.self_link
  allow_global_access    = true
}
