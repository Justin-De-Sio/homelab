variable "name" {
  description = "VM name"
  type        = string
}

variable "target_node" {
  description = "Proxmox node"
  type        = string
}

variable "clone_template" {
  description = "Template to clone"
  type        = string
}

variable "cores" {
  description = "CPU cores"
  type        = number
}

variable "memory" {
  description = "Memory in MB"
  type        = number
}

variable "ip_address" {
  description = "IP address"
  type        = string
}

variable "gateway" {
  description = "Gateway IP"
  type        = string
}

variable "cicustom" {
  description = "Cloud-init custom config"
  type        = string
}

variable "ciuser" {
  description = "Cloud-init user"
  type        = string
}

variable "sshkeys" {
  description = "SSH public keys"
  type        = string
}

variable "nameserver" {
  description = "DNS nameservers"
  type        = string
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
}

variable "disk_size" {
  description = "Disk size"
  type        = string
}

variable "disk_storage" {
  description = "Storage backend"
  type        = string
}

variable "tags" {
  description = "VM tags"
  type        = list(string)
  default     = []
}

variable "usb_devices" {
  # NOTE: Proxmox restricts USB passthrough of real devices to the root@pam
  # user — an API token (even from root) gets back HTTP 500 "only root can set
  # 'usbN' config for real devices". Until the provider/Proxmox lifts this,
  # the bloc here will fail to apply via Terraform and must be set manually
  # with `qm set <vmid> -usbN host=<vendor:product>` on the Proxmox node.
  # The declaration is kept for documentation and drift detection.
  description = "USB devices to passthrough (vendor:product host id, e.g. \"10c4:ea60\")"
  type = list(object({
    host = string
    usb3 = optional(bool, false)
  }))
  default = []
}
