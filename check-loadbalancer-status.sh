#!/bin/bash
set -euo pipefail

# K3s HA Status Checker

# Configuration
readonly VIP="192.168.1.8"
readonly SSH_USER="${SSH_USER:-root}"
readonly SSH_OPTS="-o ConnectTimeout=2 -o StrictHostKeyChecking=no -o BatchMode=yes -o LogLevel=ERROR"

declare -A LBS=(
  ["K3S-LB01"]="192.168.1.108"
  ["K3S-LB02"]="192.168.1.109"
)

declare -A K3S_SERVERS=(
  ["k3s-srv01"]="192.168.1.103"
  ["k3s-srv02"]="192.168.1.104"
  ["k3s-srv03"]="192.168.1.105"
)

declare -A K3S_AGENTS=(
  ["k3s-agt01"]="192.168.1.106"
  ["k3s-agt02"]="192.168.1.107"
)

# Colors
red() { echo -e "\e[31m$1\e[0m"; }
green() { echo -e "\e[32m$1\e[0m"; }
blue() { echo -e "\e[34m$1\e[0m"; }
bold() { echo -e "\e[1m$1\e[0m"; }

ssh_cmd() {
  ssh $SSH_OPTS "$SSH_USER@$1" "$2" 2>/dev/null
}

check_lb() {
  local name="$1" ip="$2"

  local result
  result=$(ssh_cmd "$ip" "
    has_vip=\$(ip -4 addr show | grep -q '$VIP' && echo yes || echo no)
    ka=\$(systemctl is-active keepalived 2>/dev/null || echo inactive)
    ha=\$(systemctl is-active haproxy 2>/dev/null || echo inactive)
    echo \"\$has_vip|\$ka|\$ha\"
  ") || { echo "  $name ($ip): $(red '✗ unreachable')"; return 1; }

  IFS='|' read -r has_vip ka ha <<< "$result"

  local status ka_icon ha_icon
  [[ "$ka" == "active" ]] && ka_icon="$(green '✓')" || ka_icon="$(red '✗')"
  [[ "$ha" == "active" ]] && ha_icon="$(green '✓')" || ha_icon="$(red '✗')"

  if [[ "$has_vip" == "yes" ]]; then
    status="$(green 'MASTER')"
    echo "  $name ($ip): $status  keepalived:$ka_icon haproxy:$ha_icon  VIP:$VIP"
    echo "$ip"
  else
    status="$(blue 'BACKUP')"
    echo "  $name ($ip): $status  keepalived:$ka_icon haproxy:$ha_icon"
  fi
}

check_haproxy_backends() {
  local lb_ip="$1"

  local csv
  csv=$(ssh_cmd "$lb_ip" "curl -sf 'http://localhost:8404/stats;csv' 2>/dev/null") || return 1

  echo "$csv" | awk -F',' '
    /^k3s_servers,k3s-srv/ { printf "    %s %s\n", ($18=="UP"?"✓":"✗"), $2 }
    /^k3s_http,k3s-agt/    { printf "    %s %s (http)\n", ($18=="UP"?"✓":"✗"), $2 }
    /^k3s_https,k3s-agt/   { printf "    %s %s (https)\n", ($18=="UP"?"✓":"✗"), $2 }
  '
}

check_api() {
  if curl -ksfm 3 "https://$VIP:6443/healthz" &>/dev/null; then
    green "✓ healthy"
  else
    red "✗ unreachable"
  fi
}

main() {
  bold "K3s HA Status"
  echo "─────────────────────────────────"

  echo "Load Balancers:"
  local master_ip=""
  for name in "${!LBS[@]}"; do
    result=$(check_lb "$name" "${LBS[$name]}")
    # First line is display, second line (if exists) is master IP
    echo "$result" | head -1
    [[ $(echo "$result" | wc -l) -gt 1 ]] && master_ip=$(echo "$result" | tail -1)
  done

  echo ""
  echo -n "API ($VIP:6443): "
  check_api

  if [[ -n "$master_ip" ]]; then
    echo ""
    echo "HAProxy Backends:"
    check_haproxy_backends "$master_ip" || echo "  $(red 'stats unavailable')"
  fi

  echo "─────────────────────────────────"
}

main "$@"
