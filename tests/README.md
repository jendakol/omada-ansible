# Omada Ansible Test Suite

Comprehensive test suite for validating Omada SDN Ansible playbooks against a production controller using an isolated test site.

## Quick Start

```bash
# Setup isolated test site
./tests/setup-test-site.sh

# Run all tests (sequential order)
./tests/run-all-tests.sh

# Run tests in random order (validates independence)
./tests/run-all-tests.sh --random

# Cleanup test site
./tests/cleanup-test-site.sh
```

## Test Coverage

All tests validate the complete lifecycle: **CREATE** → **UPDATE** → **IDEMPOTENCY**

| Test | Feature | What It Tests |
|------|---------|---------------|
| **controller_auth** | Authentication | Controller login and site selection |
| **infra_networks** | VLANs & DHCP | Network creation, DHCP auto-generation from devices |
| **wireless_ssids** | WiFi SSIDs | SSID creation, security settings, renaming |
| **security_ip_groups** | IP Groups | IP group management, adding addresses |
| **security_firewall** | Firewall Rules | ACL rules, inter-VLAN policies, rule ordering |
| **services_multicast** | mDNS Forwarding | Multicast service discovery across VLANs |
| **nat_port_forward** | Port Forwarding | NAT port forwarding, port changes |

**Status**: ✅ All tests passing (7/7 tests, 100% success rate)

## Running Tests

### Sequential Order

Run tests one after another in a fixed order:

```bash
./tests/run-all-tests.sh
```

### Random Order

Run tests in random order to validate independence:

```bash
# Random order, single run
./tests/run-all-tests.sh --random

# Random order, 3 iterations (thorough validation)
./tests/run-all-tests.sh --random --iterations 3
```

### Individual Test

Run a specific test:

```bash
# Setup fresh environment
echo "yes" | ./tests/cleanup-test-site.sh
./tests/setup-test-site.sh

# Run specific test
./tests/run-test.sh security_firewall
```

### Script Options

```bash
./tests/run-all-tests.sh --help

Options:
  -r, --random              Run tests in random order
  -i, --iterations N        Run tests N times (default: 1)
  -v, --verbose            Show test output during execution
  -h, --help               Show help message
```

## Test Architecture

### Isolated Test Site

Tests run against a dedicated "Test-Automation" site on your production controller:

- **Production site**: Remains completely untouched
- **Test site**: Isolated environment for all test operations
- **Automatic cleanup**: Test data removed when desired
- **Safe execution**: Zero risk to production

### Test Phases

Each test verifies the complete resource lifecycle:

1. **CREATE Phase**
   - Sets up infrastructure (VLANs if needed)
   - Creates resources with initial configuration
   - Verifies resources were created correctly

2. **UPDATE Phase**
   - Modifies existing configuration
   - Re-runs role with updated config
   - Verifies changes were applied

3. **ORDERING Phase** (firewall only)
   - Creates multiple rules in specific order
   - Verifies rules receive correct index values (1, 2, 3...)
   - Confirms rule ordering via modifyIndex API

4. **IDEMPOTENCY Phase**
   - Re-runs role with same config
   - Verifies no unnecessary changes made
   - Confirms true idempotent behavior

### Independence

All tests are fully standalone:
- Each test includes its own dependencies
- Tests can run in any order
- No hidden dependencies between tests
- **Validated**: 21/21 test executions passed in random order (3 iterations)

## Test Execution Times

- Individual test: 1.5-7 minutes (firewall test is longest)
- Full suite (sequential): 20-30 minutes
- Full suite (3 random iterations): 60-90 minutes

## Site Management

### Setup Test Site

```bash
./tests/setup-test-site.sh
```

Creates the "Test-Automation" site on your controller. Reuses existing site if present.

### Cleanup Test Site

```bash
./tests/cleanup-test-site.sh
```

⚠️ **Warning**: This deletes the Test-Automation site and all its data (VLANs, DHCP, WiFi, firewall rules, etc.). You will be prompted for confirmation.

## Test Configuration

Tests connect to your production controller but use a separate isolated site:

```yaml
# Location: tests/inventories/test/group_vars/all/02_controller.yml
omada_controller_url: "https://omada.home.jenda.eu"
omada_site: "Test-Automation"  # Isolated test site
omada_username: "{{ vault_omada_username }}"
omada_password: "{{ vault_omada_password }}"
```

All test data uses "Test-" prefix for easy identification:
- VLANs: Test-Trusted (10), Test-IoT (20)
- Devices: test-device-1, test-device-2
- SSIDs: Test-SSID
- Groups: Test-Group-1
- Rules: Test-Allow-Rule, Test-Port-Forward

## Requirements

- Docker (for running Ansible in container)
- Network access to Omada Controller
- Test credentials configured (see below)
- Omada Controller with admin access

### Setting Up Test Credentials

**Ansible Vault is optional.** Configure credentials with or without encryption:

**Option 1: Without Vault (simpler, recommended for private repos)**

Edit `tests/inventories/test/group_vars/all/00_controller.yml` directly:
```yaml
omada_username: "your-username"
omada_password: "your-password"
```

**Option 2: With Vault (extra security layer)**

1. Create vault password file:
```bash
mkdir -p ~/.ansible
echo "your-vault-password" > ~/.ansible/vault_pass
chmod 600 ~/.ansible/vault_pass
```

2. Create encrypted vault file:
```bash
# Create vault file (this file is gitignored - won't be committed)
cat > tests/inventories/test/group_vars/all/vault.yml << 'EOF'
---
# Test Controller Credentials
# Encrypted values for testing
vault_omada_username: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          <your-encrypted-username>

vault_omada_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          <your-encrypted-password>
EOF
```

3. Encrypt values:
```bash
# Encrypt username
ansible-vault encrypt_string 'your-username' --name 'vault_omada_username'

# Encrypt password
ansible-vault encrypt_string 'your-password' --name 'vault_omada_password'

# Copy the output into tests/inventories/test/group_vars/all/vault.yml
```

4. Reference vault variables in 00_controller.yml:
```yaml
omada_username: "{{ vault_omada_username }}"
omada_password: "{{ vault_omada_password }}"
```

**Note**: The vault.yml file is listed in `.gitignore` and will not be committed.

## Troubleshooting

### Tests Fail with "Site Not Found"

Create the test site:

```bash
./tests/setup-test-site.sh
```

### Tests Fail with "Authentication Failed"

1. Verify credentials in `tests/inventories/test/group_vars/all/00_controller.yml`
2. Check controller URL in test configuration
3. If using vault, ensure vault password file exists at `~/.ansible/vault_pass`
4. Ensure controller is accessible from your network

### Clean Slate Testing

Start completely fresh:

```bash
# Delete test site and all data
./tests/cleanup-test-site.sh

# Recreate clean test site
./tests/setup-test-site.sh

# Run tests
./tests/run-all-tests.sh
```

---

**Status**: ✅ All 7 tests passing
**Last Updated**: 2026-01-05
