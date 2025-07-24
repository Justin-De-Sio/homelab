# Load Balancer IPs for Manual Configuration
output "load_balancer_ips" {
  description = "IP addresses of load balancers for manual setup"
  value = {
    for name, lb in module.load_balancers : name => lb.ip_address
  }
}

# K3S Node IPs
output "k3s_server_nodes" {
  description = "K3s server node details"
  value = {
    for name, instance in module.k3s_nodes : name => {
      ip_address = instance.ip_address
      vmid       = instance.vmid
    } if var.k3s_nodes[name].role == "server"
  }
}

output "k3s_agent_nodes" {
  description = "K3s agent node details" 
  value = {
    for name, instance in module.k3s_nodes : name => {
      ip_address = instance.ip_address
      vmid       = instance.vmid
    } if var.k3s_nodes[name].role == "agent"
  }
} 