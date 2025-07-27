#!/bin/bash

# K3s Load Balancer Setup Script
# This script sets up HAProxy and KeepAlived for K3s cluster load balancing
# Based on K3s documentation: https://docs.k3s.io/datastore/cluster-loadbalancer

set -euo pipefail

# Configuration variables - adjust these for your environment
K3S_SERVERS=(
    "192.168.1.103:6443"
    "192.168.1.104:6443" 
    "192.168.1.105:6443"
)
VIP="192.168.1.8"
VIP_INTERFACE="eth0"  # Adjust based on your network interface
K3S_TOKEN="lb-cluster-gd"

# Script arguments
ROLE=${1:-""}  # MASTER or BACKUP

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Function to validate role parameter
validate_role() {
    if [[ "$ROLE" != "MASTER" && "$ROLE" != "BACKUP" ]]; then
        log_error "Usage: $0 <MASTER|BACKUP>"
        log_info "Example: $0 MASTER"
        log_info "Example: $0 BACKUP"
        exit 1
    fi
}

# Function to install packages
install_packages() {
    log_info "Installing HAProxy and KeepAlived..."
    
    # Update package list
    apt-get update -qq
    
    # Install packages
    apt-get install -y haproxy keepalived
    
    log_success "Packages installed successfully"
}

# Function to configure HAProxy
configure_haproxy() {
    log_info "Configuring HAProxy..."
    
    # Backup original config
    if [[ -f /etc/haproxy/haproxy.cfg ]]; then
        cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup
        log_info "Backed up original HAProxy config to /etc/haproxy/haproxy.cfg.backup"
    fi
    
    # Create HAProxy configuration
    cat > /etc/haproxy/haproxy.cfg << EOF
global
    log stdout local0
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    mode http
    log global
    option httplog
    option dontlognull
    option log-health-checks
    option forwardfor except 127.0.0.0/8
    option redispatch
    retries 3
    timeout http-request 10s
    timeout queue 1m
    timeout connect 10s
    timeout client 1m
    timeout server 1m
    timeout http-keep-alive 10s
    timeout check 10s
    maxconn 3000

# K3s API Server Frontend
frontend k3s-frontend
    bind *:6443
    mode tcp
    option tcplog
    default_backend k3s-backend

# K3s API Server Backend
backend k3s-backend
    mode tcp
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 3
EOF

    # Add server entries dynamically
    local counter=1
    for server in "${K3S_SERVERS[@]}"; do
        echo "    server server-${counter} ${server} check" >> /etc/haproxy/haproxy.cfg
        ((counter++))
    done

    # Add stats page
    cat >> /etc/haproxy/haproxy.cfg << EOF

# HAProxy Stats Page
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
EOF

    log_success "HAProxy configuration created"
}

# Function to configure KeepAlived
configure_keepalived() {
    log_info "Configuring KeepAlived for role: $ROLE..."
    
    # Set priority and state based on role
    local state priority
    if [[ "$ROLE" == "MASTER" ]]; then
        state="MASTER"
        priority="200"
    else
        state="BACKUP"
        priority="100"
    fi
    
    # Backup original config if it exists
    if [[ -f /etc/keepalived/keepalived.conf ]]; then
        cp /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.backup
        log_info "Backed up original KeepAlived config to /etc/keepalived/keepalived.conf.backup"
    fi
    
    # Create KeepAlived configuration
    cat > /etc/keepalived/keepalived.conf << EOF
global_defs {
    enable_script_security
    script_user root
    router_id $(hostname)
}

# Script to check HAProxy health
vrrp_script chk_haproxy {
    script "/bin/bash -c 'killall -0 haproxy'"
    interval 2
    weight -2
    fall 3
    rise 2
}

# VRRP instance for HAProxy VIP
vrrp_instance haproxy-vip {
    state ${state}
    interface ${VIP_INTERFACE}
    virtual_router_id 51
    priority ${priority}
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass k3s-ha-pass
    }
    virtual_ipaddress {
        ${VIP}/24
    }
    track_script {
        chk_haproxy
    }
    notify_master "/bin/echo 'Became MASTER' | logger -t keepalived"
    notify_backup "/bin/echo 'Became BACKUP' | logger -t keepalived"
    notify_fault "/bin/echo 'Fault detected' | logger -t keepalived"
}
EOF

    log_success "KeepAlived configuration created for $ROLE with priority $priority"
}

# Function to enable and start services
start_services() {
    log_info "Enabling and starting services..."
    
    # Enable services
    systemctl enable haproxy
    systemctl enable keepalived
    
    # Start HAProxy
    systemctl restart haproxy
    if systemctl is-active --quiet haproxy; then
        log_success "HAProxy started successfully"
    else
        log_error "Failed to start HAProxy"
        systemctl status haproxy
        exit 1
    fi
    
    # Start KeepAlived
    systemctl restart keepalived
    if systemctl is-active --quiet keepalived; then
        log_success "KeepAlived started successfully"
    else
        log_error "Failed to start KeepAlived"
        systemctl status keepalived
        exit 1
    fi
}

# Function to verify configuration
verify_setup() {
    log_info "Verifying load balancer setup..."
    
    echo
    log_info "Service Status:"
    systemctl status haproxy --no-pager -l
    echo
    systemctl status keepalived --no-pager -l
    
    echo
    log_info "Network Configuration:"
    ip addr show "$VIP_INTERFACE" | grep -E "(inet|state)"
    
    echo
    log_info "HAProxy Stats: http://$(hostname -I | awk '{print $1}'):8404/stats"
    log_info "K3s API Endpoint: https://${VIP}:6443"
    
    echo
    log_success "Load balancer setup completed!"
    log_warning "Remember to:"
    echo "  1. Configure the other load balancer node with the opposite role"
    echo "  2. Update your K3s agents to use: --server https://${VIP}:6443"
    echo "  3. Test the setup with: curl -k https://${VIP}:6443/ping"
}

# Function to show usage and configuration info
show_info() {
    echo
    log_info "Current Configuration:"
    echo "  VIP: $VIP"
    echo "  Interface: $VIP_INTERFACE"
    echo "  K3s Servers:"
    for server in "${K3S_SERVERS[@]}"; do
        echo "    - $server"
    done
    echo "  Role: $ROLE"
    echo
}

# Main execution
main() {
    log_info "Starting K3s Load Balancer Setup"
    
    check_root
    validate_role
    show_info
    
    # Ask for confirmation
    read -p "Do you want to proceed with this configuration? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Setup cancelled"
        exit 0
    fi
    
    install_packages
    configure_haproxy
    configure_keepalived
    start_services
    verify_setup
}

# Help function
show_help() {
    cat << EOF
K3s Load Balancer Setup Script

This script configures HAProxy and KeepAlived for K3s cluster load balancing.

Usage:
    $0 <MASTER|BACKUP>

Parameters:
    MASTER  - Configure this node as the primary load balancer
    BACKUP  - Configure this node as the backup load balancer

Configuration:
    VIP: $VIP
    K3s Servers: ${K3S_SERVERS[*]}
    Interface: $VIP_INTERFACE
EOF
}

# Handle help parameter
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    show_help
    exit 0
fi

# Run main function
main "$@" 