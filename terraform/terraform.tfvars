# Proxmox configuration
proxmox_api_url      = "https://192.168.1.101:8006/api2/json"
proxmox_tls_insecure = true

# Load balancer configuration
load_balancers = {
  "K3S-LB01" = {
    target_node = "p1"
    ip_address  = "192.168.1.106"
    cores       = 1
    memory      = 2 * 1024
  },
  "K3S-LB02" = {
    target_node = "p2" 
    ip_address  = "192.168.1.105"
    cores       = 1
    memory      = 2 * 1024
  }
}

# VM configurations
k3s_nodes = {
  "K3S-SRV01" = {
    target_node = "p1"
    ip_address  = "192.168.1.103"
    cores       = 6
    memory      = 6 * 1024
    role        = "server"
  },
  "K3S-SRV02" = {
    target_node = "p2"
    ip_address  = "192.168.1.104"
    cores       = 6
    memory      = 6 * 1024
    role        = "server"
  }
} 