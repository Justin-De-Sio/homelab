variable "name" {
  description = "Name of the load balancer VM"
  type        = string
}

variable "target_node" {
  description = "Proxmox node to deploy the load balancer on"
  type        = string
}

variable "clone_template" {
  description = "Template to clone from"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
}

variable "memory" {
  description = "Amount of memory in MB"
  type        = number
}

variable "ip_address" {
  description = "IP address for the load balancer"
  type        = string
}

variable "gateway" {
  description = "Gateway IP address"
  type        = string
}

variable "cicustom" {
  description = "Cloud-init custom configuration"
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
  description = "DNS nameserver configuration"
  type        = string
}

variable "network_bridge" {
  description = "Network bridge to use"
  type        = string
}

variable "disk_size" {
  description = "Disk size"
  type        = string
}

variable "disk_storage" {
  description = "Storage backend for disks"
  type        = string
} 