variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://p1.justindesio.com:8006/api2/json"
}

variable "proxmox_tls_insecure" {
  description = "Allow insecure TLS connections"
  type        = bool
  default     = true
}

variable "default_clone_template" {
  description = "Default template to clone from"
  type        = string
  default     = "ubuntu-24-cloudinit-template"
}

variable "default_gateway" {
  description = "Default gateway IP address"
  type        = string
  default     = "192.168.1.254"
}

variable "default_cicustom" {
  description = "Default cloud-init custom config"
  type        = string
  default     = "vendor=local:snippets/qemu-guest-agent.yml"
}

variable "default_nameserver" {
  description = "Default nameserver configuration"
  type        = string
  default     = "1.1.1.1 8.8.8.8"
}

variable "default_sshkeys" {
  description = "Default SSH public keys"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLpLys2IMyXu9n9ySiOWYYXte+XcbRxq3YCo2vmn4rk desio.j@live.fr"
}

variable "default_ciuser" {
  description = "Default cloud-init user"
  type        = string
  default     = "root"
}

variable "default_network_bridge" {
  description = "Default network bridge"
  type        = string
  default     = "vmbr0"
}

variable "default_disk_storage" {
  description = "Default disk storage"
  type        = string
  default     = "local-lvm"
}

variable "default_disk_size" {
  description = "Default disk size"
  type        = string
  default     = "100G"
}

variable "load_balancers" {
  description = "Configuration for load balancers"
  type = map(object({
    target_node = string
    cores       = number
    memory      = number
    ip_address  = string
  }))
}

variable "k3s_nodes" {
  description = "Configuration for K3S nodes"
  type = map(object({
    target_node = string
    cores       = number
    memory      = number
    ip_address  = string
    role        = string # "server" or "agent"
  }))
} 