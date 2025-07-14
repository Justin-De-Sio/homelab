resource "proxmox_vm_qemu" "K3S-SRV02" {
  vmid         = 201
  name         = "K3S-SRV02"
  target_node  = "p2"
  agent        = 1
  full_clone   = true
  clone        = "ubuntu-24-cloudinit-template"
  
  scsihw       = "virtio-scsi-single"
  boot         = "order=scsi0"
  vm_state     = "running"
  automatic_reboot = true

  cpu {
    cores = 6
  }

  memory = 8192


  ### Cloud-Init ###
  ciupgrade   = true
  cicustom    = "vendor=local:snippets/qemu-guest-agent.yml"
  nameserver  = "1.1.1.1 8.8.8.8"
  ipconfig0   = "ip=192.168.1.105/24,gw=192.168.1.254"
  skip_ipv6   = true
  sshkeys     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLpLys2IMyXu9n9ySiOWYYXte+XcbRxq3YCo2vmn4rk desio.j@live.fr"

  ciuser      = "funax"

  serial {
    id = 0
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  disks {
    scsi {
      scsi0 {
        disk {
          storage   = "local-lvm"
          size      = "100G"
          replicate = true
        }
      }
    }

    ide {
      ide1 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
  }
}