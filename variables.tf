variable "node_name" {
  type        = string
  description = "Name of the instance."
}

variable "flatcar_update_group" {
  type        = string
  description = "The name to the Flatcar Linux update manager."
  default     = "stable"
}

variable "flatcar_update_server" {
  type        = string
  description = "The URL to the Flatcar Linux update manager."
  default     = "http://public.update.flatcar-linux.net/v1/update/"
}

variable "clc_snippets" {
  type        = list(string)
  description = "List of Container Linux Config snippets."
  default     = []
}

variable "os_channel" {
  type        = string
  description = "Flatcar Container Linux channel to install from (stable, beta, alpha, edge)."
  default     = "stable"
}

variable "os_version" {
  type        = string
  description = "Flatcar Container Linux version to install (for example '2191.5.0' - see https://www.flatcar-linux.org/releases/)."
  default     = "current"
}

variable "kernel_args" {
  type        = list(string)
  description = "Additional kernel arguments to provide at PXE boot and in /usr/share/oem/grub.cfg."
  default     = []
}

variable "kernel_console" {
  type        = list(string)
  description = "The kernel arguments to configure the console at PXE boot and in /usr/share/oem/grub.cfg."
  default     = ["console=tty0", "console=ttyS0"]
}

variable "install_disk" {
  type        = string
  description = "Disk device to which the install profiles should install the operating system (e.g. /dev/sda)."
  default     = "/dev/sda"
}

variable "ssh_keys" {
  type        = list(string)
  description = "SSH public keys for user 'core'."
}

variable "matchbox_http_endpoint" {
  type        = string
  description = "Matchbox HTTP read-only endpoint (e.g. http://matchbox.example.com:8080)"
}

variable "node_mac" {
  type        = string
  description = "MAC address identifying the node/machine (e.g. 52:54:00:a1:9c:ae)."
}

variable "wipe_previous_raid" {
  type        = bool
  description = "Wipes previous RAID setup, if set to true"
  default     = false
}

variable "wipe_additional_disks" {
  type        = bool
  description = "Wipes any additional disks attached, if set to true"
  default     = false
}

variable "root_raid_name" {
  type        = string
  description = "Name of the base partitions RAID label and the array name"
  default     = "root_raid"
}

variable "raid_on_install_disk" {
  type        = bool
  description = "Pre-create a RAID partition on the install disk, if set to true"
  default     = false
}

variable "raid_level" {
  type        = string
  description = "RAID level"
  default     = "raid1"
}

variable "raid_disks" {
  type        = list(string)
  description = "List of disks to use for the root RAID array"
  default     = []
}

variable "dns_servers" {
  type        = list(string)
  description = "List of the DNS servers to use"
  default     = ["1.1.1.1#cloudflare-dns.com", "1.0.0.1#cloudflare-dns.com"]
}
