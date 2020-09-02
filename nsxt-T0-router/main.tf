# Configure the VMware NSX-T Provider
provider "nsxt" {
    version = "3.0.0"
    host = var.nsx["host"]
    username = var.nsx["user"]
    password = var.nsx["password"]
    allow_unverified_ssl = true
}

# Create the data sources we will need to refer to later

data "nsxt_policy_transport_zone" "vlantz" {
  display_name = "EDGE VLAN"
  }

data "nsxt_policy_edge_cluster" "EC3" {
  display_name = "Edge Cluster 3"
 }
data "nsxt_policy_edge_node" "edge5" {
  edge_cluster_path = data.nsxt_policy_edge_cluster.EC3.path
  display_name = "edge5"
 }
data "nsxt_policy_edge_node" "edge6" {
  edge_cluster_path = data.nsxt_policy_edge_cluster.EC3.path
  display_name = "edge6"
 }

# Create segments for the uplinks on each edge for the T0
resource "nsxt_policy_vlan_segment" "switch1" {
  display_name = "VLAN4000"
  transport_zone_path = data.nsxt_policy_transport_zone.vlantz.path
  vlan_ids     = [4000]
}
resource "nsxt_policy_vlan_segment" "switch2" {
  display_name = "VLAN4001"
  transport_zone_path = data.nsxt_policy_transport_zone.vlantz.path
  vlan_ids     = [4001]
}

# Create T0
resource "nsxt_policy_tier0_gateway" "t0_gw" {
  description               = "Tier-0 provisioned by Terraform"
  display_name              = "T0-3"
  failover_mode             = "PREEMPTIVE"
  ha_mode                   = "ACTIVE_ACTIVE"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.EC3.path

  bgp_config {
      local_as_num    = "60000"
  }
  redistribution_config {
    enabled = true
    rule {
      name  = "rule1"
      types = ["TIER0_STATIC", "TIER0_CONNECTED", "TIER1_CONNECTED"]
     }
    }
  tag {
    scope = "color"
    tag   = "blue"
  }
}

#Create T0 North/South Interfaces
resource "nsxt_policy_tier0_gateway_interface" "if1" {
  display_name           = "segment4000_interface"
  description            = "connection to segment4000"
  type                   = "SERVICE"
  gateway_path           = nsxt_policy_tier0_gateway.t0_gw.path
  segment_path           = nsxt_policy_vlan_segment.switch1.path
  edge_node_path         = data.nsxt_policy_edge_node.edge5.path
  subnets                = ["12.12.2.13/24"]
  mtu                    = 1500
}
resource "nsxt_policy_tier0_gateway_interface" "if2" {
  display_name           = "segment4001_interface"
  description            = "connection to segment4001"
  type                   = "SERVICE"
  gateway_path           = nsxt_policy_tier0_gateway.t0_gw.path
  segment_path           = nsxt_policy_vlan_segment.switch2.path
  edge_node_path         = data.nsxt_policy_edge_node.edge6.path
  subnets                = ["12.12.3.13/24"]
  mtu                    = 1500
 }