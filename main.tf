terraform {
  required_providers {
    hcxmgmt = {
      source = "adeleporte/hcx"
    }
  }
}

provider hcx {
    hcx               = "https://192.168.110.70"
    admin_username    = "admin"
    admin_password    = "VMware1!"
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
