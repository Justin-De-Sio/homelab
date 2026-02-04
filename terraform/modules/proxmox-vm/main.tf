resource "proxmox_vm_qemu" "this" {
  name        = var.name
  target_node = var.target_node
  clone       = var.clone_template
  full_clone  = true
  agent       = 1

  scsihw           = "virtio-scsi-single"
  boot             = "order=scsi0"
  vm_state         = "running"
  automatic_reboot = true
  onboot           = true

  cpu {
    cores = var.cores
  }

  memory = var.memory

  ciupgrade  = true
  cicustom   = var.cicustom
  ciuser     = var.ciuser
  sshkeys    = var.sshkeys
  ipconfig0  = "ip=${var.ip_address}/24,gw=${var.gateway}"
  nameserver = var.nameserver
  skip_ipv6  = true

  network {
    id     = 0
    model  = "virtio"
    bridge = var.network_bridge
  }

  serial {
    id = 0
  }

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

  lifecycle {
    ignore_changes = [
      network,
      clone,      # Only used at creation time
      full_clone, # Only used at creation time
    ]
  }

  tags = join(",", var.tags)
}
