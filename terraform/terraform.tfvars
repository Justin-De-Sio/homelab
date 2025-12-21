proxmox_api_url      = "https://192.168.1.102:8006/api2/json"
proxmox_tls_insecure = true
load_balancers = {
  "K3S-LB01" = {
    target_node = "p2"
    ip_address  = "192.168.1.108"
    cores       = 1
    memory      = 1 * 512
    disk_size   = "10G"
    cicustom    = "vendor=local:snippets/lb-master.yml"
  },
  "K3S-LB02" = {
    target_node = "p2"
    ip_address  = "192.168.1.109"
    cores       = 1
    memory      = 1 * 512
    disk_size   = "10G"
    cicustom    = "vendor=local:snippets/lb-backup.yml"
  }
}

k3s_nodes = {
  "K3S-SRV01" = {
    target_node = "p2"
    ip_address  = "192.168.1.103"
    cores       = 2
    memory      = 2 * 1024
    disk_size   = "50G"
    role        = "server"
  },
  "K3S-SRV02" = {
    target_node = "p2"
    ip_address  = "192.168.1.104"
    cores       = 2
    memory      = 2 * 1024
    disk_size   = "50G"
    role        = "server"
  },
  "K3S-SRV03" = {
    target_node = "p2"
    ip_address  = "192.168.1.105"
    cores       = 2
    memory      = 2 * 1024
    disk_size   = "50G"
    role        = "server"
  },
  "K3S-AGT01" = {
    target_node = "p2"
    ip_address  = "192.168.1.106"
    cores       = 6
    memory      = 11 * 1024
    disk_size   = "100G"
    role        = "agent"
  },
  "K3S-AGT02" = {
    target_node = "p2"
    ip_address  = "192.168.1.107"
    cores       = 6
    memory      = 11 * 1024
    disk_size   = "100G"
    role        = "agent"
  }
}

vpn_server = {
  target_node = "p2"
  ip_address  = "192.168.1.2"
  cores       = 1
  memory      = 512
  disk_size   = "10G"
}
