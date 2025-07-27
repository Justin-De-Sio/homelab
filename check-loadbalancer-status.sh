#!/bin/bash

# Optimized K3s HA status checker
# Usage: ./check-loadbalancer-status.sh

# Configuration
LB_NAMES=("K3S-LB01" "K3S-LB02")
LB_IPS=("192.168.1.106" "192.168.1.107")
K3S_IPS=("192.168.1.103" "192.168.1.104" "192.168.1.105")
SSH_USER=${SSH_USER:-"root"}
SSH_OPTS="-o ConnectTimeout=2 -o StrictHostKeyChecking=no -o BatchMode=yes"

# Function to check backends via HAProxy stats (single SSH call)
check_backends() {
    local master_host="$1"
    
    # Get HAProxy stats in one call
    local stats=$(ssh $SSH_OPTS "$SSH_USER@$master_host" "curl -s --connect-timeout 2 'http://localhost:8404/stats;csv' | grep 'k3s-backend,server-'" 2>/dev/null)
    
    if [[ -n "$stats" ]]; then
        echo "$stats" | awk -F',' '{
            server_ip = ($2=="server-1"?"192.168.1.103":$2=="server-2"?"192.168.1.104":"192.168.1.105")
            status = ($18=="UP"?"✅":"❌")
            printf "   %s %s (%s)\n", status, $2, server_ip
        }'
    else
        # Fallback: parallel check of K3s servers
        for ip in "${K3S_IPS[@]}"; do
            (
                if ssh $SSH_OPTS "$SSH_USER@$ip" "ss -tlnp | grep -q :6443" 2>/dev/null; then
                    echo "   ✅ K3s-server ($ip)"
                else
                    echo "   ❌ K3s-server ($ip)"
                fi
            ) &
        done
        wait
    fi
}

# Main execution
echo "🚀 K3s HA Status"
echo "==============="
echo "📡 Load Balancer Status:"

# Check both load balancers and find master
master_vip=""
master_host=""

# Check load balancers sequentially but with optimized single SSH calls
for i in "${!LB_NAMES[@]}"; do
    name="${LB_NAMES[i]}"
    host="${LB_IPS[i]}"
    
    # Single SSH call combining all checks
    result=$(ssh $SSH_OPTS "$SSH_USER@$host" '
        # Check VIP
        vip=$(ip addr show | grep -oE "inet 192\.168\.1\.[0-9]+" | grep -v "192.168.1.106\|192.168.1.107" | head -1 | cut -d" " -f2)
        
        # Check services
        keepalived=$(systemctl is-active keepalived 2>/dev/null || echo "inactive")
        haproxy=$(systemctl is-active haproxy 2>/dev/null || echo "inactive")
        
        # Output format: VIP|keepalived|haproxy
        echo "${vip:-none}|$keepalived|$haproxy"
    ' 2>/dev/null)
    
    if [[ -z "$result" ]]; then
        echo "📡 $name ($host): ❌ SSH Failed"
        continue
    fi
    
    IFS='|' read -r vip keepalived haproxy <<< "$result"
    
    echo -n "📡 $name ($host): "
    if [[ "$vip" != "none" ]]; then
        echo "🟢 MASTER (has VIP) | keepalived: $keepalived | haproxy: $haproxy"
        echo "   └── VIP: $vip"
        master_vip="$vip"
        master_host="$host"
    else
        echo "🔵 BACKUP | keepalived: $keepalived | haproxy: $haproxy"
    fi
done

# API and Backend checks (if master found)
if [[ -n "$master_vip" && -n "$master_host" ]]; then
    # API check
    echo -n "🔗 API: "
    if curl -k --connect-timeout 2 --max-time 3 https://$master_vip:6443 >/dev/null 2>&1; then
        if command -v kubectl &>/dev/null; then
            node_count=$(kubectl --server=https://$master_vip:6443 --insecure-skip-tls-verify get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
            echo "✅ Active ($node_count nodes)"
        else
            echo "✅ Active"
        fi
    else
        echo "❌ Failed"
    fi
    
    # Backend check
    echo "🖥️  Backends:"
    check_backends "$master_host"
fi

echo "===============" 