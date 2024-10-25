module "hub-mgt-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.hub-prj.project_id
  name       = "gcp-vpc-hub-net-cor-004"
  delete_default_routes_on_create = true
  mtu        = 1500

  # Set explicit routes for googleapis in case the default route is deleted
  routes = {
    to-internet-hub-mgmt = {
      dest_range    = "0.0.0.0/0"
      priority      = 10
      tags          = []
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
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
    win-kms-license = {
      dest_range    = "35.190.247.13/32"
      priority      = 100
      tags          = []
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
  }

  dns_policy = {
    inbound  = false
    logging  = false
    outbound = null
  }

  data_folder = "${var.data_dir}/subnets/hub-mgt"
}

module "hub-mgmt-firewall" {
  source              = "../../../modules/net-vpc-firewall"
  project_id          = module.hub-prj.project_id
  network             = module.hub-mgt-vpc.name
  admin_ranges        = [] #172.26.255.64/28
  http_source_ranges  = []
  https_source_ranges = []
  ssh_source_ranges   = []
  data_folder         = "${var.data_dir}/firewall-rules/hub-mgt"
  cidr_template_file  = "${var.data_dir}/cidrs.yaml"
}

module "hub-mgmt-nat-ew8" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.hub-prj.project_id
  region         = "europe-west8"
  name           = "gcp-nat-hub-mgt-cor-ew8-001"
  router_create  = true
  router_name    = "gcp-rtr-hub-mgt-cor-ew8-001"
  router_network = module.hub-mgt-vpc.name
  router_asn     = 4200001024
  config_source_subnets = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}