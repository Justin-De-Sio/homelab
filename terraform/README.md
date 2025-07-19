# Terraform K3S Infrastructure

## What This Does
Creates a **4-node K3S Kubernetes cluster** on Proxmox VMs:
- 2 server nodes (control plane) 
- 2 agent nodes (workers)
- High availability across 2 physical Proxmox hosts

## Infrastructure Overview
| Node       | IP            | Host | Role   | CPU | RAM |
|------------|---------------|------|--------|-----|-----|
| K3S-SRV01  | 192.168.1.103 | p1   | server | 6   | 8GB |
| K3S-SRV02  | 192.168.1.104 | p2   | server | 6   | 8GB |
| K3S-AGT01  | 192.168.1.105 | p1   | agent  | 4   | 4GB |
| K3S-AGT02  | 192.168.1.106 | p2   | agent  | 4   | 4GB |

## Prerequisites
1. Run `ubuntu-24-cloudinit-template.sh` on Proxmox first
2. Set environment variables:
   ```bash
   export PM_API_TOKEN_ID="your-token-id"
   export PM_API_TOKEN_SECRET="your-token-secret"
   ```

## Usage
```bash
# Deploy infrastructure
terraform init
terraform plan
terraform apply

# Get node information
terraform output k3s_servers  # For K3S server setup
terraform output k3s_agents   # For K3S agent setup

# Destroy everything
terraform destroy
```

## File Structure Explanation

### Core Files
- **`main.tf`** - Main entry point, creates VMs using the k3s-node module
- **`variables.tf`** - Defines all configurable parameters (defaults, VM specs, network settings)
- **`terraform.tfvars`** - Actual values for variables (VM specifications and IP addresses)
- **`providers.tf`** - Configures Proxmox provider connection
- **`terraform.tf`** - Terraform version requirements and provider versions
- **`outputs.tf`** - Exports node information for K3S setup and Ansible integration

### Module: `modules/k3s-node/`
- **`main.tf`** - Creates individual Proxmox VMs with cloud-init configuration
- **`variables.tf`** - Module interface (accepts VM name, resources, network settings)
- **`outputs.tf`** - Returns VM information (ID, IP, role) to main configuration

### Supporting Files
- **`ubuntu-24-cloudinit-template.sh`** - Script to create Ubuntu 24.04 template on Proxmox
- **`.terraform.lock.hcl`** - Provider version lock file
- **`terraform.tfstate`** - Current infrastructure state (managed by Terraform)

## Adding/Removing Nodes
Edit `terraform.tfvars` and add/remove entries in `k3s_nodes`:
```hcl
"K3S-AGT03" = {
  target_node = "p1"
  ip_address  = "192.168.1.107"
  cores       = 4
  memory      = 4056
  role        = "agent"
}
```

## Configuration
- **Network**: 192.168.1.0/24, gateway 192.168.1.254
- **Template**: ubuntu-24-cloudinit-template
- **User**: funax (SSH key auth only)
- **Storage**: local-lvm on each Proxmox node

## Common Issues
| Problem | Solution |
|---------|----------|
| Template not found | Run the template script first |
| Auth failed | Check environment variables |
| IP conflicts | Verify IPs are available |
| Can't SSH | Wait for cloud-init, check SSH key |

## Next Steps
1. Use `terraform output` to get node IPs
2. Install K3S on server nodes first
3. Join agent nodes to the cluster
4. Deploy applications 