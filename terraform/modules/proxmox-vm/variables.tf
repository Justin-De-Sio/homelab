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
