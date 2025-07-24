output "vm_id" {
  description = "The VM ID of the load balancer"
  value       = proxmox_vm_qemu.this.vmid
}

output "ip_address" {
  description = "The IP address of the load balancer"
  value       = var.ip_address
} 