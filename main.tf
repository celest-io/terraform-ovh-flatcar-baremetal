
// Profile to set an SSH authorized key on first boot from disk
resource "matchbox_profile" "nodes-provision" {
  name   = "${var.node_name}-provision"
  kernel = "http://${var.os_channel}.release.flatcar-linux.net/amd64-usr/${var.os_version}/flatcar_production_pxe.vmlinuz"
  initrd = [
    "http://${var.os_channel}.release.flatcar-linux.net/amd64-usr/${var.os_version}/flatcar_production_pxe_image.cpio.gz",
  ]

  args = flatten([
    "initrd=flatcar_production_pxe_image.cpio.gz",
    "flatcar.config.url=${var.matchbox_http_endpoint}/ignition?uuid=$${uuid}&mac=$${mac:hexhyp}",
    "flatcar.first_boot=yes",
    "consoleblank=0",
    var.kernel_console,
    var.kernel_args,
  ])

  container_linux_config = templatefile("${path.module}/config/flatcar-install.yaml", {
    ssh_keys              = jsonencode(var.ssh_keys)
    install_disk          = var.install_disk
    kernel_console        = join(" ", var.kernel_console)
    kernel_args           = join(" ", var.kernel_args)
    wipe_previous_raid    = var.wipe_previous_raid
    wipe_additional_disks = var.wipe_additional_disks
    raid_on_install_disk  = var.raid_on_install_disk
    root_raid_name        = var.root_raid_name
    os_channel            = var.os_channel
    os_version            = var.os_version
    ignition_endpoint     = "${var.matchbox_http_endpoint}/ignition"
    mac_address           = var.node_mac
  })
}

resource "matchbox_group" "nodes-provision" {
  name    = "${var.node_name}-provision"
  profile = matchbox_profile.nodes-provision.name

  selector = {
    mac = var.node_mac
  }

  metadata = {
    ignition_endpoint = "${var.matchbox_http_endpoint}/ignition"
    install_disk      = var.install_disk
    hostname          = var.node_name
  }
}

data "ct_config" "node" {
  content = templatefile("${path.module}/config/config.yaml", {
    ssh_keys       = jsonencode(var.ssh_keys)
    hostname       = var.node_name
    update_group   = var.flatcar_update_group
    update_server  = var.flatcar_update_server
    root_disk      = var.install_disk
    root_raid_name = var.root_raid_name
    raid_level     = var.raid_level
    raid_disks     = var.raid_disks
    dns_servers    = join(" ", var.dns_servers)
  })
  platform     = "custom"
  pretty_print = true
  snippets     = var.clc_snippets
}

// Profile to set an SSH authorized key on first boot from disk
resource "matchbox_profile" "nodes" {
  name         = "${var.node_name}-installed"
  raw_ignition = data.ct_config.node.rendered
}

resource "matchbox_group" "nodes" {
  name    = "${var.node_name}-installed"
  profile = matchbox_profile.nodes.name

  selector = {
    os  = "installed"
    mac = var.node_mac
  }

  metadata = {
    #ssh_authorized_key = var.ssh_keys
    hostname      = var.node_name
    update_group  = var.flatcar_update_group
    update_server = var.flatcar_update_server
  }
}

data "ovh_dedicated_server_boots" "harddisk" {
  service_name = var.node_name
  boot_type    = "harddisk"
}

data "ovh_dedicated_server_boots" "ipxe" {
  service_name = var.node_name
  boot_type    = "ipxeCustomerScript"
}

resource "ovh_dedicated_server_update" "server_on_ipxe" {
  service_name = var.node_name
  boot_id      = data.ovh_dedicated_server_boots.ipxe.result[0]
  monitoring   = false
  state        = "ok"
  lifecycle {
    ignore_changes = [monitoring]
  }
}

resource "ovh_dedicated_server_reboot_task" "server_reboot" {
  service_name = var.node_name

  keepers = [
    ovh_dedicated_server_update.server_on_ipxe.boot_id,
  ]
}

resource "null_resource" "os_installed" {
  depends_on = [ovh_dedicated_server_reboot_task.server_reboot]
  triggers = {
    status = ovh_dedicated_server_reboot_task.server_reboot.status
  }

  connection {
    host = var.node_name
    port = 2222
    user = "core"
  }

  provisioner "remote-exec" {
    inline = [
      "test /opt/installer"
    ]
  }
}

resource "ovh_dedicated_server_update" "server_on_harddisk" {
  depends_on   = [null_resource.os_installed]
  service_name = var.node_name
  boot_id      = data.ovh_dedicated_server_boots.harddisk.result[0]
  monitoring   = true
  state        = "ok"
  lifecycle {
    ignore_changes = [boot_id]
  }
}
