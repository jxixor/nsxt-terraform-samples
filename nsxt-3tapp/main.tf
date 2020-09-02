# Configure the VMware NSX-T Provider
provider "nsxt" {
    version = "3.0.0"
    host = var.nsx["host"]
    username = var.nsx["user"]
    password = var.nsx["password"]
    allow_unverified_ssl = true
}

# Create the data sources we will need to refer to later
data "nsxt_policy_transport_zone" "overlay_tz" {
  display_name = "overlay"
  }
data "nsxt_policy_tier0_gateway" "T0" {
  display_name = "T0"
   }
data "nsxt_policy_edge_cluster" "EC" {
  display_name = "Edge Cluster 1"
 }
data "nsxt_policy_service" "dns" {
  display_name = "DNS"
}
data "nsxt_policy_service" "http" {
  display_name = "HTTP"
}
data "nsxt_policy_service" "mssql1" {
  display_name = "MSSQL Server Database Engine"
}
data "nsxt_policy_lb_app_profile" "tcp" {
  type         = "TCP"
}

# Create T1 Gateway
resource "nsxt_policy_tier1_gateway" "tier1_gw" {
  description               = "Tier-1 provisioned by Terraform"
  display_name              = "Terraform T1"
  nsx_id                    = "predefined_id"
  failover_mode             = "PREEMPTIVE"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.EC.path
  default_rule_logging      = "false"
  enable_firewall           = "true"
  force_whitelisting        = "true"
  tier0_path                = data.nsxt_policy_tier0_gateway.T0.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED", "TIER1_LB_VIP", "TIER1_DNS_FORWARDER_IP"]
  pool_allocation           = "ROUTING"
  tag {
    scope = "color"
    tag   = "blue"
  }
}
# Create Web Tier NSX-T Logical Switches
resource "nsxt_policy_segment" "web" {
    display_name        = "3TA Web"
    description         = "Terraform provisioned Segment"
    connectivity_path   = nsxt_policy_tier1_gateway.tier1_gw.path
    transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
    subnet {
      cidr        = "10.0.1.1/24"
        }
  }

resource "nsxt_policy_segment" "app" {
    display_name        = "3TA App"
    description         = "Terraform provisioned Segment"
    connectivity_path   = nsxt_policy_tier1_gateway.tier1_gw.path
    transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
    subnet {
      cidr        = "10.0.2.1/24"
        }
      }

resource "nsxt_policy_segment" "db" {
    display_name        = "3TA DB"
    description         = "Terraform provisioned Segment"
    connectivity_path   = nsxt_policy_tier1_gateway.tier1_gw.path
    transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
    subnet {
      cidr        = "10.0.3.1/24"
        }
    }
# Create NSGROUP with dynamic membership criteria
# all Virtual Machines with the specific tag and scope
# Create NSXGroup
resource "nsxt_policy_group" "TA3SG" {
    display_name = "3TA SG"
    description  = "Terraform provisioned Group"
    criteria {
        condition {
            key         = "Tag"
            member_type = "VirtualMachine"
            operator    = "STARTSWITH"
            value       = "3TA"
        }
      }  
    }
resource "nsxt_policy_group" "TA3AppSG" {
    display_name = "3TA App SG"
    description  = "Terraform provisioned Group"
    criteria {
        condition {
            key         = "Tag"
            member_type = "VirtualMachine"
            operator    = "EQUALS"
            value       = "production|3TAapp"
        }
      }
   }
resource "nsxt_policy_group" "TA3WebSG" {
    display_name = "3TA Web SG"
    description  = "Terraform provisioned Group"
    criteria {
        condition {
            key         = "Tag"
            member_type = "VirtualMachine"
            operator    = "EQUALS"
            value       = "production|3TAWeb"
        }
     }
    }
resource "nsxt_policy_group" "TA3dbSG" {
    display_name = "3TA DB SG"
    description  = "Terraform provisioned Group"
    criteria {
        condition {
            key         = "Tag"
            member_type = "VirtualMachine"
            operator    = "EQUALS"
            value       = "production|3TADB"
        }
     }
   }


#Create Security Policy
resource "nsxt_policy_security_policy" "TA3-policy" {
    display_name = "3TA Policy"
    description  = "Terraform provisioned Security Policy"
    category     = "Application"
    locked       = false
    stateful     = true
    tcp_strict   = false
    rule {
      display_name       = "any to web"
      destination_groups = [nsxt_policy_group.TA3WebSG.path]
      action             = "ALLOW"
      services           = [data.nsxt_policy_service.http.path]
      logged             = true
    }
    rule {
      display_name     = "allow_http from web to any"
      source_groups    = [nsxt_policy_group.TA3WebSG.path]
      action           = "ALLOW"
      services         = [data.nsxt_policy_service.http.path]
      logged           = true
      notes            = "i don't need no stinkin notes"
    }
    rule {
      display_name     = "allow app to db"
      source_groups    = [nsxt_policy_group.TA3AppSG.path]
      destination_groups = [nsxt_policy_group.TA3dbSG.path]
      action           = "ALLOW"
      services         = [data.nsxt_policy_service.mssql1.path]
      logged           = true
      scope            = [nsxt_policy_group.TA3AppSG.path, nsxt_policy_group.TA3dbSG.path]
    }
    rule {
      display_name     = "drop any to 3TA"
      destination_groups = [nsxt_policy_group.TA3SG.path]
      action           = "ALLOW"
      logged           = true
    }
    rule {
      display_name     = "drop 3TA to any"
      source_groups    = [nsxt_policy_group.TA3SG.path]
      action           = "ALLOW"
      logged           = true
    }
}
#resource "nsxt_policy_nat_rule" "dnat1" 
#{
#  display_name         = "tf-dnat_rule1"
#  action               = "DNAT"
#  source_networks      = ["9.1.1.1", "9.2.1.1"]
#  destination_networks = ["11.1.1.1"]
#  translated_networks  = ["10.1.1.1"]
#  gateway_path         = nsxt_policy_tier1_gateway.tier1_gw.path
#  logging              = false
#  firewall_match       = "MATCH_INTERNAL_ADDRESS"
#  tag {
#    scope = "tf_color"
#    tag   = "tf_blue"
#  }
#}
#resource "xt_policy_lb_pool" "tf-lb1-serverpool" {
#    display_name         = "tf-lb1-serverpool"
#    description          = "Terraform provisioned LB Server Pool"
#    algorithm            = "IP_HASH"
#    min_active_members   = 2
#    active_monitor_path  = "/infra/lb-monitor-profiles/default-icmp-lb-monitor"
#    passive_monitor_path = "/infra/lb-monitor-profiles/default-passive-lb-monitor"
#    member {
#      admin_state                = "ENABLED"
#      backup_member              = false
#      display_name               = "tfmember1"
#      ip_address                 = "5.5.5.5"
#      max_concurrent_connections = 12
#      port                       = "77"
#      weight                     = 1
#    }
#    snat {
#       type = "AUTOMAP"
#    }
#    tcp_multiplexing_enabled = true
#    tcp_multiplexing_number  = 8
#}
#resource "nsxt_policy_lb_service" "tf-lb1-service" {
#  display_name      = "tf-lb1-service"
#  description       = "Terraform provisioned Service"
#  connectivity_path = nsxt_policy_tier1_gateway.tier1_gw.path
#  size = "SMALL"
#  enabled = true
#  error_log_level = "ERROR"
#}
#resource "nsxt_policy_lb_virtual_server" "tf-lb1-VIP" {
#  display_name               = "tf-lb1-VIP"
#  description                = "Terraform provisioned Virtual Server"
#  access_log_enabled         = true
#  application_profile_path   = data.nsxt_policy_lb_app_profile.tcp.path
#  enabled                    = true
#  ip_address                 = "10.10.10.21"
#  ports                      = ["80"]
#  default_pool_member_ports  = ["80"]
#  service_path               = nsxt_policy_lb_service.tf-lb1-service.path
#  max_concurrent_connections = 6
#  max_new_connection_rate    = 20
#  pool_path                  = nsxt_policy_lb_pool.tf-lb1-serverpool.path
#}
