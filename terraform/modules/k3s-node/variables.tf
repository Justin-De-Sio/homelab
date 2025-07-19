variable "name" {
  description = "Name of the VM"
  type        = string
}

variable "target_node" {
  description = "Proxmox node to deploy to"
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
  description = "IP address for the VM"
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
  description = "Nameserver configuration"
  type        = string
}

variable "network_bridge" {
  description = "Network bridge to use"
  type        = string
}

variable "disk_size" {
  description = "Disk size (unused in v3.x - inherits from template)"
  type        = string
  default     = "100G"
}

variable "disk_storage" {
  description = "Storage for the disk (unused in v3.x - inherits from template)"
  type        = string
  default     = "local-lvm"
}

variable "role" {
  description = "Role of the node (server or agent)"
  type        = string
  validation {
    condition     = contains(["server", "agent"], var.role)
    error_message = "Role must be either 'server' or 'agent'."
  }
} 