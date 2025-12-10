output "vm_id" {
  description = "VM ID"
  value       = proxmox_vm_qemu.this.vmid
}

output "ip_address" {
  description = "VM IP address"
  value       = var.ip_address
}
