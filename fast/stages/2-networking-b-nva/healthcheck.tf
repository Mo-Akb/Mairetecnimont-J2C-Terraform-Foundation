#ILB regional healthcheck for FortiGate instances
resource "google_compute_region_health_check" "lnd_health_check" {
  name                   = "gcp-hck-lnd-http-${var.healthcheck_port}-${var.region_trigram}-001"
  project                = module.lnd-prj.project_id
  region                 = var.region
  timeout_sec            = 2
  check_interval_sec     = 2

  http_health_check {
    port                 = var.healthcheck_port
  }
}

resource "google_compute_region_health_check" "hub_health_check" {
  name                   = "gcp-hck-hub-http-${var.healthcheck_port}-${var.region_trigram}-001"
  project                = module.hub-prj.project_id
  region                 = var.region
  timeout_sec            = 2
  check_interval_sec     = 2

  http_health_check {
    port                 = var.healthcheck_port
  }
}