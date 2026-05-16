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
  usb_devices    = each.value.usb_devices
  tags           = [each.value.role, "k3s"]
}

module "ai_agent_server" {
  source = "./modules/proxmox-vm"

  name           = "ai-agent"
  target_node    = var.ai_agent_server.target_node
  clone_template = var.default_clone_template
  cores          = var.ai_agent_server.cores
  memory         = var.ai_agent_server.memory
  ip_address     = var.ai_agent_server.ip_address
  gateway        = var.default_gateway
  disk_size      = var.ai_agent_server.disk_size
  cicustom       = var.default_cicustom
  ciuser         = var.default_ciuser
  sshkeys        = var.default_sshkeys
  nameserver     = var.default_nameserver
  network_bridge = var.default_network_bridge
  disk_storage   = var.default_disk_storage
  tags           = ["ai-agent"]
}
