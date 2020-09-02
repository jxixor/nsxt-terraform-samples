# Configure the VMware NSX-T Provider
provider "nsxt" {
    host = var.nsx["ip"]
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
data "nsxt_policy_service" "dnsservice" {
  display_name = "DNS"
}
data "nsxt_policy_service" "ntpservice" {
  display_name = "NTP Time Server"
}
data "nsxt_policy_service" "httpservice" {
  display_name = "HTTP"
}
data "nsxt_policy_lb_app_profile" "tcp" {
  type         = "TCP"
}



# Create NSGROUP with dynamic membership criteria
# all Virtual Machines with the specific tag and scope
resource "nsxt_policy_group" "quarantinegroup" {
    display_name = "Quarantine-tf"
    description  = "All VMs that need to be blocked from the network."
    criteria {
        condition {
            key         = "Tag"
            member_type = "VirtualMachine"
            operator    = "EQUALS"
            value       = "quarantine"
        }
    }
}
resource "nsxt_policy_group" "DNSgroup" {
    display_name = "DNS-tf"
    description  = "DMS Servers Group"
    criteria {
        ipaddress_expression {
            ip_addresses = ["10.99.1.203", "10.99.1.1", "8.8.8.8"]
        }
    }
   }
   resource "nsxt_policy_group" "NTPgroup" {
    display_name = "NTP-tf"
    description  = "DMS Servers Group"
    criteria {
        ipaddress_expression {
            ip_addresses = ["10.99.1.203"]
        }
    }
   }
resource "nsxt_policy_group" "ADgroup" {
    display_name = "AD-tf"
    description  = "AD Server Group"
    criteria {
        ipaddress_expression {
            ip_addresses = ["10.99.1.109", "10.99.1.203"]
        }
    }
    }
resource "nsxt_policy_group" "NFSgroup" {
    display_name = "NFS-tf"
    description  = "NFS Server Group"
    criteria {
        ipaddress_expression {
            ip_addresses = ["10.99.1.203"]
        }
    }
   }
resource "nsxt_policy_group" "Productiongroup" {
    display_name = "Production-tf"
    description  = "Terraform provisioned Group"
    criteria {
        condition {
            key         = "Tag"
            member_type = "VirtualMachine"
            operator    = "EQUALS"
            value       = "production|"
        }
    }
   }
resource "nsxt_policy_group" "Developmentgroup" {
    display_name = "Development-tf"
    description  = "Terraform provisioned Group"
    criteria {
        condition {
            key         = "Tag"
            member_type = "VirtualMachine"
            operator    = "EQUALS"
            value       = "development|"
        }
    }
   }
   resource "nsxt_policy_group" "QAgroup" {
    display_name = "QA-tf"
    description  = "Terraform provisioned Group"
    criteria {
        condition {
            key         = "Tag"
            member_type = "VirtualMachine"
            operator    = "EQUALS"
            value       = "QA|"
        }
    }
   }
#Create Quarntine Security Policy
resource "nsxt_policy_security_policy" "QuarantineSP" {
    display_name = "Quarantine tf SP"
    description  = "Terraform provisioned Security Policy"
    category     = "Emergency"
    rule {
      display_name       = "To Quarantine"
      destination_groups = [nsxt_policy_group.quarantinegroup.path]
      action             = "DROP"
      logged             = true
    }
    rule {
      display_name     = "from Quarantine"
      source_groups    = [nsxt_policy_group.quarantinegroup.path]
      action           = "DROP"
      logged           = true
    }
}
#Create Shared Services Policy Group
resource "nsxt_policy_security_policy" "Shared-Services-SP" {
    display_name = "Shared Services tf SP"
    description  = "Terraform provisioned Security Policy"
    category     = "Infrastructure"
    rule {
      display_name       = "NTPrule"
      destination_groups = [nsxt_policy_group.NTPgroup.path]
      action             = "ALLOW"
      services           = [data.nsxt_policy_service.ntpservice.path]
      logged             = false
    }
    rule {
      display_name     = "DNSrule"
      source_groups    = [nsxt_policy_group.DNSgroup.path]
      action           = "ALLOW"
      services         = [data.nsxt_policy_service.dnsservice.path]
      logged           = false
    }
    rule {
      display_name     = "NFSrule"
      source_groups    = [nsxt_policy_group.NFSgroup.path]
      action           = "ALLOW"
      logged           = false
    }
    rule {
      display_name     = "ADrule"
      source_groups    = [nsxt_policy_group.ADgroup.path]
      action           = "ALLOW"
      logged           = false
    }
}

#Create DEV to QA to Prod Policy Group
resource "nsxt_policy_security_policy" "Dev-Prod-QA-SP" {
    display_name = "Dev to QA to Prod tf SP"
    description  = "Terraform provisioned Security Policy"
    category     = "Environment"
    rule {
      display_name       = "Prod to DEV and QA"
      source_groups      = [nsxt_policy_group.Productiongroup.path]
      destination_groups = [nsxt_policy_group.Developmentgroup.path, nsxt_policy_group.QAgroup.path]
      action             = "DROP"
      logged             = false
    }
    rule {
      display_name       = "DEV to prod and QA"
      source_groups      = [nsxt_policy_group.Developmentgroup.path]
      destination_groups = [nsxt_policy_group.Productiongroup.path, nsxt_policy_group.QAgroup.path]
      action             = "DROP"
      logged             = false
    }
    rule {
      display_name       = "QA to DEV and prod"
      source_groups      = [nsxt_policy_group.QAgroup.path]
      destination_groups = [nsxt_policy_group.Developmentgroup.path, nsxt_policy_group.Productiongroup.path]
      action             = "DROP"
      logged             = false
    }
}