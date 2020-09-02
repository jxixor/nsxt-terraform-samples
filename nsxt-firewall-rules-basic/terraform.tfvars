nsx = {
  ip       = "10.99.1.194"
  user     = "admin"
  password = "Vmware1!VMware1!"
}
nsx_data_vars = {
  transport_zone = "overlay"
  t0_router_name = "T0"
  edge_cluster   = "Edge Cluster 1"
  t1_router_name = "tf-router2"
}
nsx_rs_vars = {
  t1_router_name = "tf-router2"
}

ipset = ["10.19.12.201", "10.29.12.219", "10.29.12.220"]


nsx_tag_scope = "project"
nsx_tag       = "terraform-demo"

vsphere = {
  vsphere_user     = "administrator@vsphere.local"
  vsphere_password = "VMware1!"
  vsphere_ip       = "10.99.1.100"
  dc               = "DC2"
  datastore        = "SynologyISCSI1"
  #    resource_pool = "T_Cluster/Resources"
  #    vm_template = "t_template_novra"
}


app_listen_port = "8443"

db_user = "medicalappuser" # Database details 
db_name = "medicalapp"
db_pass = "VMware1!"

dns_server_list = ["10.99.1.203", "8.8.8.8"]


web = {
  ip      = "10.29.15.210"
  gw      = "10.29.15.209"
  mask    = "28"
  nat_ip  = "" # If the ip above is routable and has internet access you can leave the NAT IP blank
  vm_name = "web"
  domain  = "jdmlab.local"
  user    = "root" # Credentails to access the VM
  pass    = "VMware1!"
}

app = {
  ip      = "192.168.245.21" # If this IP is not routable and has no internet access you need to condigure a NAT IP below
  gw      = "192.168.245.1"
  mask    = "24"
  nat_ip  = "10.29.15.229"
  vm_name = "app"
  domain  = "jdmlab.local"
  user    = "root"
  pass    = "VMware1!"
}

db = {
  ip      = "192.168.247.21"
  gw      = "192.168.247.1"
  mask    = "24"
  nat_ip  = "10.29.15.228"
  vm_name = "db"
  domain  = "jdmlab.local"
  user    = "root"
  pass    = "VMware1!"
}

