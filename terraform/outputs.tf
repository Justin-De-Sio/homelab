# VM Information
output "k3s_nodes" {
  description = "Information about all K3S nodes"
  value = {
    for k, v in module.k3s_nodes : k => {
      id          = v.id
      vmid        = v.vmid
      ip_address  = v.ip_address
      target_node = v.target_node
      role        = v.role
    }
  }
}

# Server nodes for K3S cluster setup
output "k3s_servers" {
  description = "K3S server nodes"
  value = {
    for k, v in module.k3s_nodes : k => {
      ip_address = v.ip_address
      vmid       = v.vmid
    } if v.role == "server"
  }
}

# Agent nodes for K3S cluster setup
output "k3s_agents" {
  description = "K3S agent nodes"
  value = {
    for k, v in module.k3s_nodes : k => {
      ip_address = v.ip_address
      vmid       = v.vmid
    } if v.role == "agent"
  }
}

# Ansible inventory helper
output "ansible_inventory" {
  description = "Ansible inventory formatted output"
  value = {
    k3s_servers = [
      for k, v in module.k3s_nodes : {
        name       = k
        ip_address = v.ip_address
      } if v.role == "server"
    ]
    k3s_agents = [
      for k, v in module.k3s_nodes : {
        name       = k
        ip_address = v.ip_address
      } if v.role == "agent"
    ]
  }
} 