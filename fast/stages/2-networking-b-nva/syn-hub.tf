module "hub-syn-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.hub-prj.project_id
  name       = "gcp-vpc-hub-net-cor-003"
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
  }
  
  dns_policy = {
    inbound  = false
    logging  = false
    outbound = null
  }

  data_folder = "${var.data_dir}/subnets/hub-syn"
}

module "hub-syn-fw" {
  source              = "../../../modules/net-vpc-firewall"
  project_id          = module.hub-prj.project_id
  network             = module.hub-syn-vpc.name
  admin_ranges        = []
  http_source_ranges  = []
  https_source_ranges = []
  ssh_source_ranges   = []
  data_folder         = "${var.data_dir}/firewall-rules/hub-syn"
  cidr_template_file  = "${var.data_dir}/cidrs.yaml"
}
