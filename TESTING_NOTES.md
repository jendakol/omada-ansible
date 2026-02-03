# Testing Notes - Omada Ansible Playbook

## Current Status

### ✅ Working Components

1. **Authentication (omada_controller role)**
   - Successfully connects to controller at https://omada.home.jenda.eu
   - Retrieves controller ID: `02fad0d0d35bc874f243cd93695c9849`
   - Controller version: `6.0.0.25`
   - Authenticates successfully with API v2
   - Discovers sites with pagination
   - Found site "doma" with ID: `6944323f836e41425b5c4498`
   - Properly constructs API base URL
   - Session tokens work correctly

### ⚠️ Issues Encountered

1. **Network/VLAN Creation (vlans role)**
   - Endpoint: `/setting/lan/networks` requires specific parameters
   - API is very strict about the `domain` field - rejects empty strings
   - Tried endpoints:
     - `/setting/lan/networks` - "Invalid request parameters" / "Enter valid domain"
     - `/settings/profiles/networks` - "Unsupported request path"
   - **Next Steps**: Need to inspect actual network creation in the Omada Controller UI to determine exact API format

### Configuration Used

```yaml
vlans:
  - id: 10
    name: "Trusted"
    subnet: "192.168.10.0/24"
    gateway: "192.168.10.1"
    dhcp_enabled: true
```

Network payload attempted:
```json
{
  "name": "Trusted",
  "vlanId": "10",
  "gateway": "192.168.10.1",
  "mask": "255.255.255.0",
  "networkType": "LAN",
  "purpose": "GENERAL",
  "dhcpEnable": true,
  "ipv6Enable": false,
  "igmpSnoopEnable": true
}
```

## Recommendations

1. **To fix network creation**:
   - Open browser developer tools on the Omada Controller UI
   - Create a network manually
   - Capture the exact API request (endpoint, method, headers, body)
   - Update the playbook with the correct format

2. **Alternative approach**:
   - Create networks manually in the UI first
   - Use the playbook for WiFi, firewall, and other configurations
   - The authentication framework is solid and can be built upon

3. **Testing other roles**:
   - Once networks exist, test WiFi configuration
   - Test firewall rules
   - Test port forwarding

## API Endpoints Discovered

- Authentication: `/{omadacId}/api/v2/login` ✅
- Sites list: `/{omadacId}/api/v2/sites?currentPage=1&currentPageSize=50` ✅
- Networks list: `/{omadacId}/api/v2/sites/{siteId}/setting/lan/networks?currentPage=1&currentPageSize=50` ✅
- Networks create: `/{omadacId}/api/v2/sites/{siteId}/setting/lan/networks` ❌ (needs correct payload format)

## Running the Playbook

```bash
docker run --rm --add-host=host.docker.internal:host-gateway \
  -e ANSIBLE_REMOTE_TMP=/tmp -e ANSIBLE_LOCAL_TMP=/tmp \
  -v /home/jan.kolena/dev/omada-ansible:/ansible \
  -v /home/jan.kolena/.ansible/vault_pass:/root/vault_pass:ro \
  -w /ansible quay.io/ansible/ansible-runner \
  ansible-playbook playbooks/site.yml \
  -i inventories/production/hosts.yml \
  --vault-password-file /root/vault_pass
```

## Fixed Issues

1. ✅ Fixed `hosts.yml` - removed extraneous docker command
2. ✅ Added pagination to sites endpoint
3. ✅ Fixed netmask calculation (removed ansible.utils dependency)
4. ✅ Improved error handling and debug output

## Next Actions

1. Determine correct network creation API format
2. Test remaining roles (wifi, firewall, port_forward)
3. Validate idempotency of all operations
4. Add better error messages for common issues
