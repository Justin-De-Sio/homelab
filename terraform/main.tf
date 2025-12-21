module "load_balancers" {
  source   = "./modules/proxmox-vm"
  for_each = var.load_balancers

  name           = each.key
  target_node    = each.value.target_node
  clone_template = var.default_clone_template
  cores          = each.value.cores
  memory         = each.value.memory
  ip_address     = each.value.ip_address
  gateway        = var.default_gateway
  disk_size      = each.value.disk_size
  cicustom       = each.value.cicustom
  ciuser         = var.default_ciuser
  sshkeys        = var.default_sshkeys
  nameserver     = var.default_nameserver
  network_bridge = var.default_network_bridge
  disk_storage   = var.default_disk_storage
  tags           = ["load-balancer", "haproxy", "keepalived", "k3s"]
}

module "k3s_nodes" {
  source   = "./modules/proxmox-vm"
  for_each = var.k3s_nodes

  name           = each.key
  target_node    = each.value.target_node
  clone_template = var.default_clone_template
  cores          = each.value.cores
  memory         = each.value.memory
  ip_address     = each.value.ip_address
  gateway        = var.default_gateway
  disk_size      = each.value.disk_size
  cicustom       = var.default_cicustom
  ciuser         = var.default_ciuser
  sshkeys        = var.default_sshkeys
  nameserver     = var.default_nameserver
  network_bridge = var.default_network_bridge
  disk_storage   = var.default_disk_storage
  tags           = [each.value.role, "k3s"]
}

module "vpn_server" {
  source = "./modules/proxmox-vm"

  name           = "VPN-Tailscale"
  target_node    = var.vpn_server.target_node
  clone_template = var.default_clone_template
  cores          = var.vpn_server.cores
  memory         = var.vpn_server.memory
  ip_address     = var.vpn_server.ip_address
  gateway        = var.default_gateway
  disk_size      = var.vpn_server.disk_size
  cicustom       = var.default_cicustom
  ciuser         = var.default_ciuser
  sshkeys        = var.default_sshkeys
  nameserver     = var.default_nameserver
  network_bridge = var.default_network_bridge
  disk_storage   = var.default_disk_storage
  tags           = ["vpn", "tailscale"]
}
