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

module "peering-hub" {
  source        = "../../../modules/net-vpc-peering"
  prefix        = "cor-peering"
  local_network = module.hub-ext-vpc.self_link
  peer_network  = module.lnd-int-vpc.self_link
  export_local_custom_routes = try(
    var.peering_configs.prd.export_local_custom_routes, null
  )
  export_peer_custom_routes = try(
    var.peering_configs.prd.export_peer_custom_routes, null
  )
}

module "peering-col" {
  source        = "../../../modules/net-vpc-peering"
  prefix        = "col-peering"
  local_network = module.col-spk-vpc.self_link
  peer_network  = module.hub-int-vpc.self_link
  depends_on    = [module.peering-hub]
  export_local_custom_routes = try(
    var.peering_configs.col.export_local_custom_routes, null
  )
  export_peer_custom_routes = try(
    var.peering_configs.col.export_peer_custom_routes, null
  )
}

module "peering-tst" {
  source        = "../../../modules/net-vpc-peering"
  prefix        = "tst-peering"
  local_network = module.tst-spk-vpc.self_link
  peer_network  = module.hub-int-vpc.self_link
  depends_on    = [module.peering-col]
  export_local_custom_routes = try(
    var.peering_configs.tst.export_local_custom_routes, null
  )
  export_peer_custom_routes = try(
    var.peering_configs.tst.export_peer_custom_routes, null
  )
}

module "peering-prd" {
  source        = "../../../modules/net-vpc-peering"
  prefix        = "prd-peering"
  local_network = module.prd-spk-vpc.self_link
  peer_network  = module.hub-int-vpc.self_link
  depends_on    = [module.peering-tst]
  export_local_custom_routes = try(
    var.peering_configs.prd.export_local_custom_routes, null
  )
  export_peer_custom_routes = try(
    var.peering_configs.prd.export_peer_custom_routes, null
  )
}

module "peering-shr" {
  source        = "../../../modules/net-vpc-peering"
  prefix        = "shr-peering"
  local_network = module.shr-spk-vpc.self_link
  peer_network  = module.hub-int-vpc.self_link
  depends_on    = [module.peering-col]
  export_local_custom_routes = try(
    var.peering_configs.shr.export_local_custom_routes, null
  )
  export_peer_custom_routes = try(
    var.peering_configs.shr.export_peer_custom_routes, null
  )
}

module "peering-shr-tst" {
  source        = "../../../modules/net-vpc-peering"
  prefix        = "shr-tst-peering"
  local_network = module.shr-spk-vpc-tst.self_link
  peer_network  = module.hub-int-vpc.self_link
  depends_on    = [module.peering-col]
  export_local_custom_routes = try(
    var.peering_configs.shr.export_local_custom_routes, null
  )
  export_peer_custom_routes = try(
    var.peering_configs.shr.export_peer_custom_routes, null
  )
}

### FortiManager

module "peering-lnd-int-mgt" {
  source        = "../../../modules/net-vpc-peering"
  prefix        = "cor-peering"
  local_network = module.lnd-int-vpc.self_link
  peer_network  = module.lnd-mgt-vpc.self_link
  export_local_custom_routes = try(
    var.peering_configs.prd.export_local_custom_routes, null
  )
  export_peer_custom_routes = try(
    var.peering_configs.prd.export_peer_custom_routes, null
  )
}

module "peering-lnd-int-mgt-hub" {
  source        = "../../../modules/net-vpc-peering"
  prefix        = "cor-peering"
  local_network = module.lnd-int-vpc.self_link
  peer_network  = module.hub-mgt-vpc.self_link
  export_local_custom_routes = try(
    var.peering_configs.prd.export_local_custom_routes, null
  )
  export_peer_custom_routes = try(
    var.peering_configs.prd.export_peer_custom_routes, null
  )
}