# Omada SDN Ansible Library

Reusable Ansible library for managing TP-Link Omada SDN Controller configurations as code.

## **IMPORTANT NOTES**

- The bad news: This repo is 99% vibe-coded.
- The good news: I did this primarily for me, so I believe it actually works :)

## Overview

This Ansible library provides Infrastructure as Code (IaC) for managing TP-Link Omada SDN Controller configurations,
including:

- **VLANs/Networks**: Create and manage network segments with DHCP
- **WiFi/WLANs**: Configure wireless networks with security settings
- **PPSK (Private Pre-Shared Key)**: Multiple passwords on one SSID for different VLAN assignment
- **DHCP Reservations**: Static IP assignments by MAC address
- **IP Groups**: Logical groupings for firewall rules (IP groups and IP-Port groups)
- **Firewall Policies**: Implement inter-VLAN isolation and access control
- **Port Forwarding**: Configure NAT port forwarding rules
- **WireGuard VPN**: Manage VPN server and peer configurations
- **Multicast Services**: Enable mDNS/Bonjour forwarding across VLANs

### What is missing

Intentionally, this playbook is missing complete WAN settings (besides other things I didn't need). The main reason is
the great complexity of it, and I can't really imagine reverse-engineering the whole API.

## Architecture: Two-Repository Pattern

This project uses a **separation of concerns** approach with two repositories:

```
┌─────────────────────────────────────┐
│  omada-ansible (PUBLIC)             │
│  ├── playbooks/roles/               │  ◄─── You git pull for updates
│  ├── scripts/                       │
│  ├── examples/                      │
│  └── schemas/                       │
└─────────────────────────────────────┘
                  │
                  │ reads from
                  ▼
┌─────────────────────────────────────┐
│  my-omada-config (PRIVATE)          │
│  └── inventories/production/        │  ◄─── Your private configuration
│      └── group_vars/all/            │
│          ├── 00_controller.yml      │       (Your controller URL,
│          ├── infra_networks.yml     │        passwords, VLANs,
│          ├── wireless_ssids.yml     │        firewall rules, etc.)
│          └── ...                    │
└─────────────────────────────────────┘
```

**Benefits:**

- **Security**: Your network configuration stays private
- **Updates**: Pull library updates without affecting your config
- **Validation**: Built-in checks prevent configuration errors
- **Version Control**: Track network changes in your own repo
- **Portability**: Use the same library for multiple sites

## Requirements

- Ansible 2.9 or later
- Python 3.6 or later with `yaml` module
- TP-Link Omada Controller (tested
  on [Docker image v 6.0.0.25](https://hub.docker.com/layers/mbentley/omada-controller/6.0.0.25/images/sha256-631f544e25074b89af278c276469d7cc30a967ec8a6b4be3aa3b5d678ff6e717) )
- Network access to the Omada Controller

## Quick Start

### 1. Clone the Library

```bash
git clone https://github.com/yourusername/omada-ansible.git
cd omada-ansible
```

### 2. Initialize Your Configuration

Create a new private configuration repository from the examples:

```bash
./scripts/init-config.sh ../my-omada-config
```

This creates:

```
../my-omada-config/
├── .gitignore
├── README.md
├── vault-template.yml
└── inventories/production/
    ├── hosts.yml
    └── group_vars/all/
        ├── 00_controller.yml
        ├── infra_devices.yml
        ├── infra_networks.yml
        ├── wireless_ssids.yml
        ├── security_ip_groups.yml
        ├── security_firewall.yml
        ├── services_multicast.yml
        ├── services_vpn.yml
        └── nat_port_forward.yml
```

### 3. Configure Your Network

Edit the configuration files in your private repository:

```bash
cd ../my-omada-config
vim inventories/production/group_vars/all/00_controller.yml    # Set controller URL
vim inventories/production/group_vars/all/infra_networks.yml   # Define VLANs
vim inventories/production/group_vars/all/wireless_ssids.yml   # Configure WiFi
# ... edit other files as needed
```

### 4. Secure Sensitive Data (Optional)

**Ansible Vault is optional.** If your configuration repository is private, you can store credentials directly in your
config files without encryption.

**Without Vault (recommended for private repos):**

```yaml
# In your 00_controller.yml
omada_username: "admin"
omada_password: "your-password-here"
```

**With Vault (for extra security):**

If you want additional encryption layer, set up Ansible Vault:

```bash
# Create vault password file
mkdir -p ~/.ansible
echo "your-vault-password" > ~/.ansible/vault_pass
chmod 600 ~/.ansible/vault_pass

# Encrypt sensitive values
ansible-vault encrypt_string 'your-controller-password' --name 'vault_omada_password'
ansible-vault encrypt_string 'your-wifi-password' --name 'vault_wifi_password_main'

# Copy the encrypted output into your configuration files
```

See `vault-template.yml` in your config repo for more examples.

**Migrating from Vault to plain credentials:**

If you're already using vault and want to stop:

1. Decrypt your vault values:
   ```bash
   # View encrypted values
   ansible-vault view inventories/production/group_vars/all/vault.yml
   ```

2. Copy the plaintext values to your config files:
   ```yaml
   # In 00_controller.yml, change from:
   omada_password: "{{ vault_omada_password }}"
   # To:
   omada_password: "actual-password-here"
   ```

3. Delete vault files:
   ```bash
   rm inventories/production/group_vars/all/vault.yml
   rm ~/.ansible/vault_pass  # Optional
   ```

### 5. Validate Configuration

Before applying, validate your configuration:

```bash
cd /path/to/omada-ansible
./scripts/validate-config.sh ../my-omada-config/inventories/production
```

This checks for:

- YAML syntax errors
- Required fields
- MAC address format
- VLAN ID conflicts
- Controller URL format

### 6. Apply Configuration

```bash
cd /path/to/omada-ansible

# Apply all configuration (first time)
ansible-playbook -i ../my-omada-config/inventories/production playbooks/site.yml

# For quick updates, apply only what changed (much faster):
ansible-playbook -i ../my-omada-config/inventories/production playbooks/site.yml --tags firewall
```

**Tip:** Use `--tags` to apply only specific sections - this is much faster than applying everything. Available tags:
`vlans`, `dhcp`, `wifi`, `ppsk`, `ip_groups`, `firewall`, `multicast`, `wireguard`, `port_forward`.

### 7. Version Control Your Configuration

Keep your configuration in a **private** git repository:

```bash
cd ../my-omada-config
git init
git add .
git commit -m "Initial Omada configuration"
git remote add origin <your-private-repo-url>
git push -u origin main
```

**Important**: Keep this repository private! It contains your network topology and may contain sensitive information.

## Usage

### Making Changes to Your Configuration

After initial setup, when you need to modify your network:

1. **Edit your configuration** in the private repository:
   ```bash
   cd /path/to/my-omada-config
   vim inventories/production/group_vars/all/infra_networks.yml   # Add a VLAN
   vim inventories/production/group_vars/all/wireless_ssids.yml   # Change WiFi settings
   ```

2. **Validate the changes**:
   ```bash
   cd /path/to/omada-ansible
   ./scripts/validate-config.sh ../my-omada-config/inventories/production
   ```

3. **Apply to controller**:
   ```bash
   # Apply all configuration
   ansible-playbook -i ../my-omada-config/inventories/production playbooks/site.yml

   # Or apply only specific sections (faster)
   ansible-playbook -i ../my-omada-config/inventories/production playbooks/site.yml --tags firewall
   ansible-playbook -i ../my-omada-config/inventories/production playbooks/site.yml --tags ip_groups,firewall
   ```

   **Available tags for partial updates:**
    - `vlans` - Network/VLAN configuration
    - `dhcp` - DHCP reservations
    - `wifi` - WiFi SSIDs and wireless settings
    - `ppsk` - PPSK profiles
    - `ip_groups` - IP groups and IP-Port groups
    - `firewall` - Firewall ACL rules
    - `multicast` - Multicast/mDNS forwarding
    - `wireguard` - WireGuard VPN
    - `port_forward` - Port forwarding rules
    - `cleanup` - Auto-cleanup operations

   Use tags to speed up deployments when you only changed one section.

   **Note on WiFi with PPSK:** The `wifi` tag automatically fetches PPSK profiles when needed, so you can use
   `--tags wifi` alone even for WiFi networks that use PPSK profiles. SSIDs with regular passwords will work
   independently. If a PPSK profile is unavailable, SSIDs using it will be skipped with a warning, but regular
   password-based SSIDs will still be created.

4. **Commit your changes**:
   ```bash
   cd /path/to/my-omada-config
   git add .
   git commit -m "Add IoT VLAN and guest WiFi network"
   git push
   ```

### Updating the Library

To get the latest features and bug fixes:

```bash
cd /path/to/omada-ansible
git pull origin main
```

Your private configuration repository is separate, so library updates won't affect your settings.

### Common Workflows

**Add a new WiFi network:**

```bash
# 1. Edit WiFi config
vim ../my-omada-config/inventories/production/group_vars/all/wireless_ssids.yml

# 2. Validate
./scripts/validate-config.sh ../my-omada-config/inventories/production

# 3. Apply only WiFi changes
ansible-playbook -i ../my-omada-config/inventories/production playbooks/site.yml --tags wifi
```

**Add firewall rule between VLANs:**

```bash
# 1. Edit firewall config
vim ../my-omada-config/inventories/production/group_vars/all/security_firewall.yml

# 2. Validate
./scripts/validate-config.sh ../my-omada-config/inventories/production

# 3. Apply only firewall changes
ansible-playbook -i ../my-omada-config/inventories/production playbooks/site.yml --tags firewall
```

**Dry run (check what would change):**

```bash
ansible-playbook -i ../my-omada-config/inventories/production playbooks/site.yml --check
```

**Test in a different environment:**

```bash
# Create staging config
./scripts/init-config.sh ../my-omada-config-staging

# Edit for staging environment
vim ../my-omada-config-staging/inventories/production/group_vars/all/00_controller.yml

# Apply to staging
ansible-playbook -i ../my-omada-config-staging/inventories/production playbooks/site.yml
```

### Working with Multiple Sites

If you manage multiple Omada sites:

```bash
# Initialize separate configs for each site
./scripts/init-config.sh ../omada-config-home
./scripts/init-config.sh ../omada-config-office
./scripts/init-config.sh ../omada-config-lab

# Apply to different sites
ansible-playbook -i ../omada-config-home/inventories/production playbooks/site.yml
ansible-playbook -i ../omada-config-office/inventories/production playbooks/site.yml
ansible-playbook -i ../omada-config-lab/inventories/production playbooks/site.yml
```

### Best Practices

1. **Always validate before applying**: Catch errors early with `validate-config.sh`
2. **Use version control**: Commit every change to track your network's evolution
3. **Test with --check first**: See what will change before applying
4. **Use tags for targeted updates**: Only update specific resources with `--tags`
5. **Keep sensitive data secure**: Use private repository or Ansible Vault for passwords
6. **Document your changes**: Use descriptive git commit messages
7. **Back up before major changes**: Create a controller backup first
8. **Update library regularly**: Get bug fixes and new features with `git pull`

## Architecture

### Roles

The playbook is organized into modular roles:

#### omada_controller

Establishes authenticated session with the Omada Controller API.

- Retrieves controller ID
- Authenticates with username/password
- Discovers sites
- Sets up session tokens and headers

#### vlans

Creates and manages VLAN/network profiles.

- Idempotent network creation/updates
- Automatic CIDR to netmask conversion
- DHCP configuration per VLAN
- Supports multiple VLANs

#### wifi

Configures wireless networks (SSIDs).

- WPA2/WPA3 security modes
- VLAN assignment
- Client isolation
- Guest network settings
- Hidden SSID support

#### firewall_policies

Implements firewall ACL rules for network segmentation.

- IoT VLAN isolation
- Guest network restrictions
- Inter-VLAN access control
- WAN access policies

#### port_forward

Manages NAT port forwarding rules.

- TCP/UDP protocol support
- External to internal port mapping
- Enable/disable individual rules

#### wireguard

Configures WireGuard VPN server and peers.

- VPN server setup
- Peer management
- Subnet configuration
- Automatic detection of controller support

#### multicast_services

Enables mDNS/Bonjour forwarding across VLANs.

- Service discovery between networks
- Fallback to manual configuration guidance

## Configuration

All configuration files are located in your private repository at `inventories/production/group_vars/all/`. Each file is
well-documented with examples and best practices.

### Configuration Files

| File                     | Purpose                                            |
|--------------------------|----------------------------------------------------|
| `00_controller.yml`      | Controller connection settings (required)          |
| `infra_devices.yml`      | Device registry (incl. optional DHCP reservations) |
| `infra_networks.yml`     | VLAN/network configuration                         |
| `wireless_ssids.yml`     | WiFi SSID configuration                            |
| `security_ip_groups.yml` | IP groups and IP-Port groups for firewall rules    |
| `security_firewall.yml`  | Firewall ACL rules                                 |
| `services_multicast.yml` | mDNS/multicast forwarding                          |
| `services_vpn.yml`       | WireGuard VPN configuration                        |
| `nat_port_forward.yml`   | Port forwarding/NAT rules                          |

### Example Configuration Snippets

See the `examples/` directory for complete configuration examples with extensive comments.

**VLAN Configuration** (`infra_networks.yml`):

```yaml
vlans:
  - id: 10
    name: "Trusted"
    subnet: "192.168.10.0/24"           # Both .0/24 and .1/24 formats work
    dhcp_enabled: true                  # Role converts to gatewaySubnet "192.168.10.1/24"
    dhcp_range_start: "192.168.10.101"  # Optional, default: .1
    dhcp_range_end: "192.168.10.254"    # Optional, default: .254
    dns_servers: # Optional, default: auto DNS
      - "8.8.8.8"
    lease_time: 120                      # Optional, default: 120 minutes
```

**WiFi Configuration** (`wireless_ssids.yml`):

```yaml
ssids:
  - name: "Home-WiFi"
    vlan: "Trusted"
    password: "{{ vault_wifi_password_main }}"
    security: "wpa2-wpa3-personal"
    enabled: true
```

**Firewall Rules** (`security_firewall.yml`):

```yaml
firewall_policies:
  - name: "block-iot-to-trusted"
    enabled: true
    action: drop
    protocol: all
    source_network: "IoT"
    dest_network: "Trusted"
```

**Port Forwarding** (`nat_port_forward.yml`):

```yaml
port_forward_rules:
  - name: "web-server"
    enabled: true
    external_port: "80"
    forward_device: "server-01"  # Device from infra_devices.yml (recommended)
    forward_port: "8080"
    protocol: tcp
```

## Running Specific Roles

Use tags to run specific configurations:

```bash
# Only configure VLANs
ansible-playbook -i ../my-omada-config/inventories/production playbooks/site.yml --tags vlans

# Only configure WiFi
ansible-playbook -i ../my-omada-config/inventories/production playbooks/site.yml --tags wifi

# Configure VLANs and WiFi
ansible-playbook -i ../my-omada-config/inventories/production playbooks/site.yml --tags vlans,wifi

# Skip WireGuard
ansible-playbook -i ../my-omada-config/inventories/production playbooks/site.yml --skip-tags wireguard
```

**Available tags:**

- `vlans` - VLAN/network configuration
- `dhcp` - DHCP static reservations
- `wifi` - WiFi SSID configuration
- `ip_groups` - IP address groups
- `firewall` - Firewall ACL rules
- `multicast` - mDNS forwarding
- `vpn` - WireGuard VPN
- `port_forward` - Port forwarding rules

## Advanced Configuration

### Debug Mode

Enable detailed API debugging:

```yaml
omada_api_debug: true
```

### SSL Verification

Disable SSL verification for self-signed certificates:

```yaml
verify_ssl: false
```

**Warning**: Only use this in development environments.

## Troubleshooting

### Authentication Failures

If authentication fails:

1. Verify credentials in your configuration (00_controller.yml)
2. Check controller URL is correct
3. Ensure controller is accessible
4. Check firewall rules

### API Errors

If API calls fail:

1. Enable debug mode
2. Check controller version compatibility
3. Verify the site name matches exactly
4. Review API responses in debug output

### Feature Not Supported

Some features may not be available on all controller versions:

- WireGuard requires controller v5.9+
- mDNS forwarding requires controller v5.5+

The playbook will detect unsupported features and warn accordingly.

## Project Structure

### Library Repository

```
omada-ansible/
├── README.md
├── playbooks/
│   ├── site.yml
│   └── roles/                    # Ansible roles
│       ├── omada_controller/
│       ├── vlans/
│       ├── dhcp/
│       ├── wifi/
│       ├── ip_groups/
│       ├── firewall_policies/
│       ├── port_forward/
│       ├── wireguard/
│       └── multicast_services/
├── examples/
│   └── inventories/example/     # Example configurations
│       ├── hosts.yml.example
│       └── group_vars/all/
│           ├── 00_controller.yml.example
│           ├── infra_devices.yml.example
│           ├── infra_networks.yml.example
│           └── ... (all config files)
├── schemas/                      # JSON Schema validation
│   ├── controller.schema.json
│   ├── networks.schema.json
│   └── ... (validation schemas)
├── scripts/
│   ├── init-config.sh           # Bootstrap new config
│   └── validate-config.sh       # Validate before apply
└── tests/                        # Test suite
    ├── README.md
    ├── run-all-tests.sh
    └── playbooks/
```

### Configuration Repository (yours - private)

```
my-omada-config/
├── .gitignore
├── README.md
├── vault-template.yml
└── inventories/production/
    ├── hosts.yml
    └── group_vars/all/
        ├── 00_controller.yml       # Your controller URL, credentials
        ├── infra_devices.yml       # Your device registry (DHCP auto-generated)
        ├── infra_networks.yml      # Your VLANs
        ├── wireless_ssids.yml      # Your WiFi networks
        ├── security_ip_groups.yml  # Your IP groups
        ├── security_firewall.yml   # Your firewall rules
        ├── services_multicast.yml  # Your mDNS config
        ├── services_vpn.yml        # Your VPN config
        └── nat_port_forward.yml    # Your port forwards
```

## Security Considerations

- Keep configuration repository private or use Ansible Vault for sensitive data
- Use strong passwords for WiFi and controller access
- Enable SSL certificate verification in production
- Regularly update controller firmware
- Review firewall rules before deployment
- Use WPA3 security when possible

## API Endpoints Used

This playbook uses the local Omada Controller API (not the cloud API). Common endpoints:

- Authentication: `/{omadacId}/api/v2/login`
- Sites: `/{omadacId}/api/v2/sites`
- Networks: `/{omadacId}/api/v2/sites/{siteId}/setting/lan/networks`
- WLANs: `/{omadacId}/api/v2/sites/{siteId}/setting/wlans`
- Firewall ACLs: `/{omadacId}/api/v2/sites/{siteId}/setting/firewall/acls`
- Port Forwarding: `/{omadacId}/api/v2/sites/{siteId}/setting/firewall/nat/portForwarding`
- WireGuard: `/{omadacId}/api/v2/sites/{siteId}/setting/vpn/wireguard`
- mDNS: `/{omadacId}/api/v2/sites/{siteId}/setting/services/mdns`

## Testing

This project includes a comprehensive test suite that validates all playbook functionality against a production Omada
controller using an isolated test site.

### Enhanced Test Suite ✅

**Status**: All tests passing with full lifecycle coverage

Tests now validate the complete lifecycle:

- **CREATE**: Initial resource creation
- **UPDATE**: Configuration modifications
- **IDEMPOTENCY**: Verify no changes on re-run

Each test is fully standalone and includes all required dependencies.

```bash
# Run all enhanced tests (02-08) in order
./tests/run-all-tests.sh

# Run tests in random order (validates independence)
./tests/run-all-tests.sh --random

# Run tests in random order 3 times (thorough validation)
./tests/run-all-tests.sh --random --iterations 3

# Run individual test
echo "yes" | ./tests/cleanup-test-site.sh
./tests/setup-test-site.sh
./tests/run-test.sh 06  # Firewall rules
```

### Test Coverage

| Test   | Feature           | Lifecycle Phases          | Status |
|--------|-------------------|---------------------------|--------|
| **02** | VLANs             | CREATE/UPDATE/IDEMPOTENCY | ✅ PASS |
| **03** | DHCP Reservations | CREATE/UPDATE/IDEMPOTENCY | ✅ PASS |
| **04** | WiFi SSIDs        | CREATE/UPDATE/IDEMPOTENCY | ✅ PASS |
| **05** | IP Groups         | CREATE/UPDATE/IDEMPOTENCY | ✅ PASS |
| **06** | Firewall Rules    | CREATE/UPDATE/IDEMPOTENCY | ✅ PASS |
| **07** | mDNS Forwarding   | CREATE/IDEMPOTENCY        | ✅ PASS |
| **08** | Port Forwarding   | CREATE/UPDATE/IDEMPOTENCY | ✅ PASS |

**Full suite**: ~15-20 minutes | **Individual tests**: 1.5-3 minutes

See [tests/README.md](tests/README.md) for detailed testing documentation.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly using the test suite
4. Submit a pull request

## Support

For issues and questions:

- Check the troubleshooting section
- Review `docs/VARIABLES.md` for configuration help
- Open an issue in the repository

## Acknowledgments

Built for TP-Link Omada SDN Controller using the local controller API (web portal API).
