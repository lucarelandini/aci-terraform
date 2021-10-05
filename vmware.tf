//by Miguel Barajas - Gnuowned



data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.vsphere_resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

// Let's wait 45 second for the EPG and Portgroups to be created

resource "time_sleep" "wait_30_seconds" {
  depends_on = [aci_application_epg.WEB_EPG,aci_application_epg.APP_EPG,aci_application_epg.DB_EPG]
  create_duration = "45s"
}

//we concatenate the tenant, app profile and epg to get the portgroup name

data "vsphere_network" "network_web" {
  name          = "${aci_tenant.tenant.name}|${aci_application_profile.test-app.name}|${aci_application_epg.WEB_EPG.name}"
  datacenter_id = data.vsphere_datacenter.dc.id
  depends_on = [time_sleep.wait_30_seconds]
}

data "vsphere_network" "network_app" {
  name          = "${aci_tenant.tenant.name}|${aci_application_profile.test-app.name}|${aci_application_epg.APP_EPG.name}"
  datacenter_id = data.vsphere_datacenter.dc.id
  depends_on = [time_sleep.wait_30_seconds]
}

data "vsphere_network" "network_db" {
  name          = "${aci_tenant.tenant.name}|${aci_application_profile.test-app.name}|${aci_application_epg.DB_EPG.name}"
  datacenter_id = data.vsphere_datacenter.dc.id
  depends_on = [time_sleep.wait_30_seconds]
}

data "vsphere_virtual_machine" "template" {
  name          = var.vsphere_vm_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

// VM CREATION WITH STATIC IPs

resource "vsphere_virtual_machine" "vm_web" {
  count = var.web_tier_count
  name             = "${var.aci_tenant_name}_terraform_web_${count.index}"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  depends_on = [aci_application_epg.WEB_EPG]

  num_cpus = var.vsphere_vm_cpu #2
  memory   = var.vsphere_vm_memory #1024
  guest_id = var.vsphere_vm_guest #"other3xLinux64Guest"
  wait_for_guest_ip_timeout = -1

  network_interface {
    network_id = data.vsphere_network.network_web.id
  }

    
  disk {
    label = "disk0"
    size  = var.vsphere_vm_disksize #20
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    linked_clone  = var.linked_clone
    timeout       = var.timeout

    customize {
      linux_options {
        host_name = "web${count.index}"
        domain = "cisco.com"
      }

    network_interface {
      ipv4_address = "10.0.1.1${count.index}"  
      ipv4_netmask = 24

    }

      ipv4_gateway = "10.0.1.1"
    }
  }
}

resource "vsphere_virtual_machine" "vm_app" {
  count = var.app_tier_count
  name             = "${var.aci_tenant_name}_terraform_app_${count.index}"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  depends_on = [aci_application_epg.APP_EPG]

  num_cpus = var.vsphere_vm_cpu #2
  memory   = var.vsphere_vm_memory #1024
  guest_id = var.vsphere_vm_guest #"other3xLinux64Guest"
  wait_for_guest_ip_timeout = -1

  network_interface {
    network_id = data.vsphere_network.network_app.id
  }

    
  disk {
    label = "disk0"
    size  = var.vsphere_vm_disksize #20
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    linked_clone  = var.linked_clone
    timeout       = var.timeout

    customize {
      linux_options {
        host_name = "app${count.index}"
        domain = "cisco.com"
      }

    network_interface {
      ipv4_address = "10.0.2.1${count.index}"  
      ipv4_netmask = 24

    }

      ipv4_gateway = "10.0.2.1"
    }
  }
}

resource "vsphere_virtual_machine" "vm_db" {
  count = var.db_tier_count
  name             = "${var.aci_tenant_name}_terraform_db_${count.index}"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  depends_on = [aci_application_epg.DB_EPG]

  num_cpus = var.vsphere_vm_cpu #2
  memory   = var.vsphere_vm_memory #1024
  guest_id = var.vsphere_vm_guest #"other3xLinux64Guest"
  wait_for_guest_ip_timeout = -1

  network_interface {
    network_id = data.vsphere_network.network_db.id
  }

    
  disk {
    label = "disk0"
    size  = var.vsphere_vm_disksize #20
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    linked_clone  = var.linked_clone
    timeout       = var.timeout

    customize {
      linux_options {
        host_name = "db${count.index}"
        domain = "cisco.com"
      }

    network_interface {
      ipv4_address = "10.0.3.1${count.index}"  
      ipv4_netmask = 24

    }

      ipv4_gateway = "10.0.3.1"
    }
  }
}


