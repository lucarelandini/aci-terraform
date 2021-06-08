
terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
      version = "1.24.3"
    }
    aci = {
      source = "CiscoDevNet/aci"
      version = "0.7.0"
    }
  
  }
}

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # if you have a self-signed cert
  allow_unverified_ssl = true
}
provider "aci" {
    # cisco-aci user name
    username = var.aci_username
    # cisco-aci password
    password = var.aci_password
    # cisco-aci url
    url      = var.aci_url
    insecure = true
}


