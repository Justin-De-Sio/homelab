resource "proxmox_vm_qemu" "this" {
  name        = var.name
  target_node = var.target_node
  clone       = var.clone_template
  full_clone  = true
  agent       = 1
  
  # v3.x specific settings
  scsihw           = "virtio-scsi-single"
  boot             = "order=scsi0"
  vm_state         = "running"
  automatic_reboot = true
  
  # CPU configuration (v3.x syntax)
  cpu {
    cores = var.cores
  }

  memory = var.memory

  # Cloud-init configuration
  ciupgrade   = true
  cicustom    = var.cicustom
  ciuser      = var.ciuser
  sshkeys     = var.sshkeys
  ipconfig0   = "ip=${var.ip_address}/24,gw=${var.gateway}"
  nameserver  = var.nameserver
  skip_ipv6   = true

  # Network configuration
  network {
    id     = 0
    model  = "virtio"
    bridge = var.network_bridge
  }

  # Serial console
  serial {
    id = 0
  }

  # Disk configuration (v3.x syntax)
  disks {
    scsi {
      scsi0 {
        disk {
          storage   = var.disk_storage
          size      = var.disk_size
          replicate = true
        }
      }
    }

    ide {
      ide1 {
        cloudinit {
          storage = var.disk_storage
        }
      }
    }
  }

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  # Tags for organization
  tags = "${var.role},k3s"
} 