provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_tls_insecure = var.proxmox_tls_insecure
  # pm_api_token_id and pm_api_token_secret are read from environment variables:
  # PM_API_TOKEN_ID and PM_API_TOKEN_SECRET
} 