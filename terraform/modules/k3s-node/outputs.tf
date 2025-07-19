output "id" {
  description = "VM ID"
  value       = proxmox_vm_qemu.this.id
}

output "name" {
  description = "VM name"
  value       = proxmox_vm_qemu.this.name
}

output "vmid" {
  description = "VM ID number"
  value       = proxmox_vm_qemu.this.vmid
}

output "ip_address" {
  description = "IP address of the VM"
  value       = var.ip_address
}

output "target_node" {
  description = "Proxmox node hosting this VM"
  value       = proxmox_vm_qemu.this.target_node
}

output "role" {
  description = "Role of this K3S node"
  value       = var.role
} 