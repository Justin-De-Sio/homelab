module "load_balancers" {
  source = "./modules/load-balancer"

  for_each = var.load_balancers

  name           = each.key
  target_node    = each.value.target_node
  clone_template = var.default_clone_template
  cores          = each.value.cores
  memory         = each.value.memory
  ip_address     = each.value.ip_address
  gateway        = var.default_gateway

  # Common configuration
  cicustom       = var.default_cicustom
  ciuser         = var.default_ciuser
  sshkeys        = var.default_sshkeys
  nameserver     = var.default_nameserver
  network_bridge = var.default_network_bridge
  disk_size      = var.default_disk_size
  disk_storage   = var.default_disk_storage
}

module "k3s_nodes" {
  source = "./modules/k3s-node"

  for_each = var.k3s_nodes

  name           = each.key
  target_node    = each.value.target_node
  clone_template = var.default_clone_template
  cores          = each.value.cores
  memory         = each.value.memory
  ip_address     = each.value.ip_address
  gateway        = var.default_gateway
  role           = each.value.role

  # Common configuration
  cicustom       = var.default_cicustom
  ciuser         = var.default_ciuser
  sshkeys        = var.default_sshkeys
  nameserver     = var.default_nameserver
  network_bridge = var.default_network_bridge
  disk_size      = var.default_disk_size
  disk_storage   = var.default_disk_storage
} 