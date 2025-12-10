#!/bin/bash
set -euo pipefail

# Flux CD Status Monitor

# Colors
red() { echo -e "\e[31m$1\e[0m"; }
green() { echo -e "\e[32m$1\e[0m"; }
yellow() { echo -e "\e[33m$1\e[0m"; }
blue() { echo -e "\e[34m$1\e[0m"; }
dim() { echo -e "\e[2m$1\e[0m"; }
bold() { echo -e "\e[1m$1\e[0m"; }

# Check if flux CLI is available, fallback to kubectl
flux_cmd() {
  if command -v flux &>/dev/null; then
    flux "$@"
  else
    echo "flux CLI not found, using kubectl" >&2
    return 1
  fi
}

status_icon() {
  case "$1" in
    True|Ready|Succeeded) green "✓" ;;
    False|Failed) red "✗" ;;
    Unknown|Suspended) yellow "⏸" ;;
    *) dim "?" ;;
  esac
}

check_git_repositories() {
  echo "Git Repositories:"

  kubectl get gitrepositories.source.toolkit.fluxcd.io -A -o json 2>/dev/null | jq -r '
    .items[] |
    "\(.metadata.namespace)/\(.metadata.name)|\(.status.conditions[-1].status // "Unknown")|\(.status.artifact.revision // "n/a" | split("/") | .[-1] | .[0:12])"
  ' | while IFS='|' read -r name status rev; do
    echo "  $(status_icon "$status") $name $(dim "($rev)")"
  done
}

check_kustomizations() {
  echo "Kustomizations:"

  kubectl get kustomizations.kustomize.toolkit.fluxcd.io -A -o json 2>/dev/null | jq -r '
    .items[] |
    "\(.metadata.namespace)/\(.metadata.name)|\(.status.conditions[-1].status // "Unknown")|\(.spec.suspend // false)|\(.status.conditions[-1].reason // "Unknown")"
  ' | sort | while IFS='|' read -r name status suspended reason; do
    if [[ "$suspended" == "true" ]]; then
      echo "  $(status_icon "Suspended") $name $(yellow "[suspended]")"
    else
      echo "  $(status_icon "$status") $name $(dim "($reason)")"
    fi
  done
}

check_helm_releases() {
  echo "Helm Releases:"

  local releases
  releases=$(kubectl get helmreleases.helm.toolkit.fluxcd.io -A -o json 2>/dev/null | jq -r '
    .items[] |
    "\(.metadata.namespace)/\(.metadata.name)|\(.status.conditions[-1].status // "Unknown")|\(.spec.suspend // false)|\(.spec.chart.spec.version // "latest")|\(.status.conditions[-1].reason // "Unknown")"
  ' | sort)

  if [[ -z "$releases" ]]; then
    echo "  $(dim "none")"
    return
  fi

  echo "$releases" | while IFS='|' read -r name status suspended version reason; do
    if [[ "$suspended" == "true" ]]; then
      echo "  $(status_icon "Suspended") $name $(dim "v$version") $(yellow "[suspended]")"
    else
      echo "  $(status_icon "$status") $name $(dim "v$version") $(dim "($reason)")"
    fi
  done
}

check_helm_repositories() {
  echo "Helm Repositories:"

  kubectl get helmrepositories.source.toolkit.fluxcd.io -A -o json 2>/dev/null | jq -r '
    .items[] |
    "\(.metadata.namespace)/\(.metadata.name)|\(.status.conditions[-1].status // "Unknown")|\(.spec.url)"
  ' | while IFS='|' read -r name status url; do
    echo "  $(status_icon "$status") $name"
  done
}

check_failed() {
  echo "Failed Resources:"

  local output=""

  # Check Kustomizations
  output+=$(kubectl get kustomizations.kustomize.toolkit.fluxcd.io -A -o json 2>/dev/null | jq -r '
    .items[] | select(.status.conditions[-1].status == "False" and (.spec.suspend // false) == false) |
    "  Kustomization: \(.metadata.namespace)/\(.metadata.name) - \(.status.conditions[-1].message // "unknown error" | .[0:80])"
  ' 2>/dev/null || true)

  # Check HelmReleases
  local hr_json
  hr_json=$(kubectl get helmreleases.helm.toolkit.fluxcd.io -A -o json 2>/dev/null) || true
  if [[ -n "$hr_json" ]] && echo "$hr_json" | jq -e '.items | length > 0' &>/dev/null; then
    output+=$(echo "$hr_json" | jq -r '
      .items[] | select(.status.conditions[-1].status == "False" and (.spec.suspend // false) == false) |
      "  HelmRelease: \(.metadata.namespace)/\(.metadata.name) - \(.status.conditions[-1].message // "unknown error" | .[0:80])"
    ' 2>/dev/null || true)
  fi

  if [[ -n "$output" ]]; then
    echo "$output" | while read -r line; do
      [[ -n "$line" ]] && red "$line"
    done
  else
    echo "  $(green "none")"
  fi
}

show_summary() {
  local ks_json hr_json
  local total_ks=0 ready_ks=0 suspended_ks=0 failed_ks=0
  local total_hr=0 ready_hr=0 suspended_hr=0 failed_hr=0

  ks_json=$(kubectl get kustomizations.kustomize.toolkit.fluxcd.io -A -o json 2>/dev/null) || true
  if [[ -n "$ks_json" ]]; then
    total_ks=$(echo "$ks_json" | jq '.items | length' 2>/dev/null || echo 0)
    ready_ks=$(echo "$ks_json" | jq '[.items[] | select(.status.conditions[-1].status == "True")] | length' 2>/dev/null || echo 0)
    suspended_ks=$(echo "$ks_json" | jq '[.items[] | select(.spec.suspend == true)] | length' 2>/dev/null || echo 0)
    failed_ks=$(echo "$ks_json" | jq '[.items[] | select(.status.conditions[-1].status == "False" and (.spec.suspend // false) == false)] | length' 2>/dev/null || echo 0)
  fi

  hr_json=$(kubectl get helmreleases.helm.toolkit.fluxcd.io -A -o json 2>/dev/null) || true
  if [[ -n "$hr_json" ]]; then
    total_hr=$(echo "$hr_json" | jq '.items | length' 2>/dev/null || echo 0)
    ready_hr=$(echo "$hr_json" | jq '[.items[] | select(.status.conditions[-1].status == "True")] | length' 2>/dev/null || echo 0)
    suspended_hr=$(echo "$hr_json" | jq '[.items[] | select(.spec.suspend == true)] | length' 2>/dev/null || echo 0)
    failed_hr=$(echo "$hr_json" | jq '[.items[] | select(.status.conditions[-1].status == "False" and (.spec.suspend // false) == false)] | length' 2>/dev/null || echo 0)
  fi

  echo "Summary:"
  echo "  Kustomizations: $(green "$ready_ks")/$total_ks ready"
  [[ "$suspended_ks" -gt 0 ]] && echo "                  $(yellow "$suspended_ks suspended")"
  [[ "$failed_ks" -gt 0 ]] && echo "                  $(red "$failed_ks failed")"

  echo "  HelmReleases:   $(green "$ready_hr")/$total_hr ready"
  [[ "$suspended_hr" -gt 0 ]] && echo "                  $(yellow "$suspended_hr suspended")" || true
  [[ "$failed_hr" -gt 0 ]] && echo "                  $(red "$failed_hr failed")" || true
}

reconcile() {
  local resource="$1"
  echo "Triggering reconciliation for $resource..."

  if command -v flux &>/dev/null; then
    flux reconcile source git flux-system
    flux reconcile kustomization "$resource" 2>/dev/null || \
      flux reconcile helmrelease "$resource" 2>/dev/null || \
      echo "Resource not found"
  else
    kubectl annotate --overwrite gitrepository/flux-system -n flux-system \
      reconcile.fluxcd.io/requestedAt="$(date +%s)"
  fi
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [command]

Commands:
  (none)      Show full status
  summary     Show summary only
  failed      Show only failed resources
  watch       Watch status (refresh every 5s)
  reconcile   Trigger reconciliation

Examples:
  $(basename "$0")              # Full status
  $(basename "$0") summary      # Quick summary
  $(basename "$0") watch        # Live monitoring
  $(basename "$0") reconcile flux-system
EOF
}

main() {
  local cmd="${1:-}"

  case "$cmd" in
    summary)
      bold "Flux Status"
      echo "─────────────────────────────────"
      show_summary
      echo "─────────────────────────────────"
      ;;
    failed)
      bold "Flux Failed Resources"
      echo "─────────────────────────────────"
      check_failed
      echo "─────────────────────────────────"
      ;;
    watch)
      watch -c -n 5 "$0" summary
      ;;
    reconcile)
      reconcile "${2:-flux-system}"
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      bold "Flux Status"
      echo "─────────────────────────────────"
      check_git_repositories
      echo ""
      check_kustomizations
      echo ""
      check_helm_releases
      echo ""
      check_helm_repositories
      echo ""
      check_failed
      echo "─────────────────────────────────"
      show_summary
      echo "─────────────────────────────────"
      ;;
  esac
}

main "$@"
