terraform {
  required_providers {
    hcxmgmt = {
      source = "adeleporte/hcxmgmt"
      version = "0.1.1"
    }
  }
}

provider hcxmgmt {
    hcx         = "https://192.168.110.70"
    username    = "admin"
    password    = "VMware1!"
}


resource "hcxmgmt_vcenter" "vcenter" {
    url         = "https://vcsa-01a.corp.local"
    username    = "administrator@vsphere.local"
    password    = "VMware1!"

    depends_on  = [hcxmgmt_activation.activation]
}

resource "hcxmgmt_sso" "sso" {
    vcenter     = hcxmgmt_vcenter.vcenter.id
    url         = "https://vcsa-01a.corp.local"
}

variable "hcx_activation_key" {
  type        = string
  description = "Activation key (export TF_VAR_hcx_activation_key=...)"
}

resource "hcxmgmt_activation" "activation" {
    activationkey = var.hcx_activation_key
}


resource "hcxmgmt_rolemapping" "rolemapping" {
    sso = hcxmgmt_sso.sso.id

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

resource "hcxmgmt_location" "location" {
    city        = "Paris"
    country     = "France"
    province    = "Ile-de-France"
    latitude    = 48.86669293
    longitude   = 2.333335326
}
