terraform {
  required_providers {
    hcx = {
      source = "adeleporte/hcx"
    }
  }
}

provider hcx {
    hcx               = "https://192.168.110.70"
    admin_username    = "admin"
    admin_password    = "VMware1!"
    username          = "administrator@vsphere.local"
    password          = "VMware1!"
}


resource "hcx_vcenter" "vcenter" {
    url         = "https://vcsa-01a.corp.local"
    username    = "administrator@vsphere.local"
    password    = "VMware1!"

    depends_on  = [hcx_activation.activation]
}

resource "hcx_sso" "sso" {
    vcenter     = hcx_vcenter.vcenter.id
    url         = "https://vcsa-01a.corp.local"
}

variable "hcx_activation_key" {
  type        = string
  description = "Activation key (export TF_VAR_hcx_activation_key=...)"
}

resource "hcx_activation" "activation" {
    activationkey = var.hcx_activation_key
}


resource "hcx_rolemapping" "rolemapping" {
    sso = hcx_sso.sso.id

    admin {
      user_group = "vsphere.local\\Administrators"
    }

    admin {
      user_group = "corp.local\\Administrators"
    }

    enterprise {
      user_group = "corp.local\\Administrators"
    }
}

resource "hcx_location" "location" {
    city        = "Paris"
    country     = "France"
    province    = "Ile-de-France"
    latitude    = 48.86669293
    longitude   = 2.333335326
}

resource "hcx_site_pairing" "site1" {
    url         = "https://hcx-cloud-01b.corp.local"
    username    = "administrator@vsphere.local"
    password    = "VMware1!"
  
    depends_on  = [hcx_rolemapping.rolemapping]
}

resource "hcx_network_profile" "net_management" {
  vcenter       = hcx_site_pairing.site1.local_vc
  network_name  = "HCX-Management-RegionA01"
  name          = "HCX-Management-RegionA01-profile"
  mtu           = 1500

  start_address   = "192.168.110.151"
  end_address     = "192.168.110.155"

  gateway           = "192.168.110.1"
  prefix_length     = 24
  primary_dns       = "192.168.110.10"
  secondary_dns     = ""
  dns_suffix        = "corp.local"
}



resource "hcx_network_profile" "net_uplink" {
  vcenter       = hcx_site_pairing.site1.local_vc
  network_name  = "HCX-Uplink-RegionA01"
  name          = "HCX-Uplink-RegionA01-profile"
  mtu           = 1600


  start_address   = "192.168.110.156"
  end_address     = "192.168.110.160"


  gateway           = "192.168.110.1"
  prefix_length     = 24
  primary_dns       = "192.168.110.1"
  secondary_dns     = ""
  dns_suffix        = "corp.local"
}

resource "hcx_network_profile" "net_vmotion" {
  vcenter       = hcx_site_pairing.site1.local_vc
  network_name  = "HCX-vMotion-RegionA01"
  name          = "HCX-vMotion-RegionA01-profile"
  mtu           = 1500

  start_address   = "10.10.30.151"
  end_address     = "10.10.30.155"


  gateway           = ""
  prefix_length     = 24
  primary_dns       = ""
  secondary_dns     = ""
  dns_suffix        = ""
}



resource "hcx_compute_profile" "compute_profile_1" {
  name                  = "comp1"
  datacenter            = "RegionA01-ATL"
  cluster               = "RegionA01-COMP01"
  datastore             = "RegionA01-ISCSI01-COMP01"

  management_network    = hcx_network_profile.net_management
  replication_network   = hcx_network_profile.net_management
  uplink_network        = hcx_network_profile.net_uplink
  vmotion_network       = hcx_network_profile.net_vmotion
  dvs                   = "RegionA01-vDS-COMP"

  service {
    name                = "INTERCONNECT"
  }

  service {
    name                = "WANOPT"
  }

  service {
    name                = "VMOTION"
  }

  service {
    name                = "BULK_MIGRATION"
  }

  service {
    name                = "NETWORK_EXTENSION"
  }

  service {
    name                = "DISASTER_RECOVERY"
  }

}

resource "hcx_service_mesh" "service_mesh_1" {
  name                            = "sm1"
  site_pairing                    = hcx_site_pairing.site1
  local_compute_profile           = hcx_compute_profile.compute_profile_1.name
  remote_compute_profile          = "Compute-RegionB01"

  app_path_resiliency_enabled     = false
  tcp_flow_conditioning_enabled   = false

  uplink_max_bandwidth            = 10000

  service {
    name                = "INTERCONNECT"
  }

  service {
    name                = "VMOTION"
  }

  service {
    name                = "BULK_MIGRATION"
  }

  service {
    name                = "NETWORK_EXTENSION"
  }

  service {
    name                = "DISASTER_RECOVERY"
  }

}

resource "hcx_l2_extension" "l2_extension_1" {
  site_pairing                    = hcx_site_pairing.site1
  service_mesh_name               = hcx_service_mesh.service_mesh_1.name
  source_network                  = "VM-RegionA01-vDS-COMP"

  destination_t1                  = "T1-GW"
  gateway                         = "2.2.2.2"
  netmask                         = "255.255.255.0"

}
