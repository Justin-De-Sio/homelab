proxmox_api_url      = "https://192.168.1.101:8006/api2/json"
proxmox_tls_insecure = true
load_balancers = {
  "K3S-LB01" = {
    target_node = "p1"
    ip_address  = "192.168.1.106"
    cores       = 1
    memory      = 1 * 1024
  },
  "K3S-LB02" = {
    target_node = "p2" 
    ip_address  = "192.168.1.107"
    cores       = 1
    memory      = 1 * 1024
  }
}

k3s_nodes = {
  "K3S-SRV01" = {
    target_node = "p1"
    ip_address  = "192.168.1.103"
    cores       = 8
    memory      = 10 * 1024
    disk_size   = "200G"
    role        = "server"
  },
  "K3S-SRV02" = {
    target_node = "p2"
    ip_address  = "192.168.1.104"
    cores       = 4
    memory      = 6 * 1024
    disk_size   = "200G"
    role        = "server"
  },
  "K3S-SRV03" = {
    target_node = "p2"
    ip_address  = "192.168.1.105"
    cores       = 4
    memory      = 4 * 1024
    disk_size   = "200G"
    role        = "server"
  }
} 