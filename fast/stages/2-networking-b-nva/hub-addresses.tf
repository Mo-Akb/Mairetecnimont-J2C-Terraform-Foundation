resource "google_compute_address" "hub_ext_pvt" {
  count                  = 2
  project                = module.hub-prj.project_id 
  name                   = "gcp-ip4-hub-fwl-ext-${var.region_trigram}-00${count.index+1}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = module.hub-ext-vpc.subnet_self_links["europe-west8/gcp-sub-hub-ext-cor-ew8-001"]
}

resource "google_compute_address" "hub_int_pvt" {
  count                  = 2
  project                = module.hub-prj.project_id 
  name                   = "gcp-ip4-hub-fwl-int-${var.region_trigram}-00${count.index+1}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = module.hub-int-vpc.subnet_self_links["europe-west8/gcp-sub-hub-int-cor-ew8-001"]
}

resource "google_compute_address" "hub_ilb_int" {
  project                = module.hub-prj.project_id   
  name                   = "gcp-ip4-hub-ilb-int-cor-${var.region_trigram}-001"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = module.hub-int-vpc.subnet_self_links["europe-west8/gcp-sub-hub-int-cor-ew8-001"]
}

resource "google_compute_address" "hub_ilb_ext" {
  project                = module.hub-prj.project_id   
  name                   = "gcp-ip4-hub-ilb-ext-cor-${var.region_trigram}-001"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = module.hub-ext-vpc.subnet_self_links["europe-west8/gcp-sub-hub-ext-cor-ew8-001"]
}

resource "google_compute_address" "hub_syn_pvt" {
  count                  = 2
  project                = module.hub-prj.project_id 
  name                   = "gcp-ip4-hub-syn-cor-${var.region_trigram}-00${count.index+1}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = module.hub-syn-vpc.subnet_self_links["europe-west8/gcp-sub-hub-syn-cor-ew8-001"]
}

resource "google_compute_address" "hub_mgt_pvt" {
  count                  = 2
  project                = module.hub-prj.project_id 
  name                   = "gcp-ip4-hub-mgt-cor-${var.region_trigram}-00${count.index+1}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = module.hub-mgt-vpc.subnet_self_links["europe-west8/gcp-sub-hub-mgt-cor-ew8-001"]
}
