#!/bin/bash
# Apply Omada configuration via Ansible
#
# Usage:
#   ./ansible-apply.sh                    # Apply all configuration
#   ./ansible-apply.sh --tags firewall    # Apply only firewall rules
#   ./ansible-apply.sh --tags vlans,dhcp  # Apply multiple sections
#   ./ansible-apply.sh --list-tags        # Show available tags
#   ./ansible-apply.sh --check            # Dry run (check mode)
#   ./ansible-apply.sh -v                 # Verbose output
#
# Available tags:
#   vlans         - Network/VLAN configuration
#   dhcp          - DHCP reservations
#   wifi          - WiFi SSIDs and wireless settings
#   ppsk          - PPSK profiles (Private Pre-Shared Keys)
#   ip_groups     - IP groups and IP-Port groups
#   firewall      - Firewall ACL rules
#   multicast     - Multicast/mDNS forwarding
#   wireguard     - WireGuard VPN configuration
#   port_forward  - Port forwarding (NAT) rules
#   cleanup       - Auto-cleanup operations (use with other tags)
#
# Examples:
#   # Quick firewall rule update
#   ./ansible-apply.sh --tags firewall
#
#   # Update IP groups and firewall together
#   ./ansible-apply.sh --tags ip_groups,firewall
#
#   # Test changes without applying
#   ./ansible-apply.sh --tags firewall --check
#
#   # Apply with cleanup enabled
#   ./ansible-apply.sh --tags firewall,cleanup

set -e

# Show help if requested
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  sed -n '2,/^$/p' "$0" | grep '^#' | sed 's/^# //' | sed 's/^#//'
  exit 0
fi

# Check if vault password file exists
VAULT_PASS_FILE="$HOME/.ansible/vault_pass"
VAULT_ARGS=""
VAULT_VOLUME=""

if [ -f "$VAULT_PASS_FILE" ]; then
  echo "Using Ansible Vault (found vault password file)"
  VAULT_VOLUME="-v $VAULT_PASS_FILE:/root/vault_pass:ro"
  VAULT_ARGS="--vault-password-file /root/vault_pass"
else
  echo "Running without Ansible Vault (no vault password file found)"
  echo "Vault is optional when using a private configuration repository"
fi

# Show what will be applied
if [[ "$*" == *"--tags"* ]]; then
  TAGS=$(echo "$*" | grep -oP '(?<=--tags )[^ ]+' || echo "$*" | grep -oP '(?<=--tags=)[^ ]+')
  echo "Applying only: $TAGS"
else
  echo "Applying all configuration (no tags specified)"
fi

docker run --rm --add-host=host.docker.internal:host-gateway \
  -e ANSIBLE_REMOTE_TMP=/tmp -e ANSIBLE_LOCAL_TMP=/tmp \
  -v $(pwd):/ansible \
  $VAULT_VOLUME \
  -w /ansible quay.io/ansible/ansible-runner \
  ansible-playbook playbooks/site.yml \
  -i inventories/production/hosts.yml \
  $VAULT_ARGS "$@"
