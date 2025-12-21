output "load_balancer_ips" {
  description = "IP addresses of load balancers for manual setup"
  value = {
    for name, lb in module.load_balancers : name => lb.ip_address
  }
}

output "k3s_server_nodes" {
  description = "K3s server node details"
  value = {
    for name, instance in module.k3s_nodes : name => {
      ip_address = instance.ip_address
      vm_id      = instance.vm_id
    } if var.k3s_nodes[name].role == "server"
  }
}

output "k3s_agent_nodes" {
  description = "K3s agent node details"
  value = {
    for name, instance in module.k3s_nodes : name => {
      ip_address = instance.ip_address
      vm_id      = instance.vm_id
    } if var.k3s_nodes[name].role == "agent"
  }
}

output "vpn_server" {
  description = "Tailscale VPN server details"
  value = {
    ip_address = module.vpn_server.ip_address
    vm_id      = module.vpn_server.vm_id
  }
} 