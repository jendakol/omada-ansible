# Auto-Cleanup Feature ⚠️

## What Is Auto-Cleanup?

When `omada_auto_cleanup: true` is set, the playbook will **delete any resources in Omada that are NOT defined in your configuration**.

This provides true **Infrastructure-as-Code** where your Omada controller exactly matches your playbook configuration.

---

## ⚠️ DANGER WARNING ⚠️

**This feature is DESTRUCTIVE and can delete production resources!**

### What Gets Deleted

When enabled, the playbook will automatically delete:

✅ **WiFi SSIDs** - Any SSID not listed in your `wifi:` configuration
✅ **VLANs/Networks** - Any VLAN not listed in your `vlans:` configuration
✅ **IP Groups** - Any IP group not listed in your `ip_groups:` configuration
✅ **Firewall ACL Rules** - Any ACL rule not listed in your `firewall_acl_rules:` configuration
✅ **WireGuard VPN Servers** - Any WireGuard server not listed in your `wireguard_servers:` configuration
✅ **WireGuard VPN Peers** - Any peer not listed under its server's `peers:` configuration
❌ **Other resources** - Not implemented yet (MAC groups, service groups, port forwarding, mDNS, etc.)

### Example Scenario - WiFi SSIDs

**Your configuration:**
```yaml
wifi:
  ssid: "Home"
```

**What exists in Omada:**
- SSID: "Home"
- SSID: "Guest-Network"
- SSID: "Old-WiFi"

**What happens when you run the playbook:**
```
✅ SSID 'Home': no changes
⚠️  Deleting SSID 'Guest-Network' (not in playbook)
⚠️  Deleting SSID 'Old-WiFi' (not in playbook)
Result: 2 SSIDs deleted
```

### Example Scenario - VLANs

**Your configuration:**
```yaml
vlans:
  - id: 10
    name: "Trusted"
  - id: 20
    name: "IoT"
```

**What exists in Omada:**
- VLAN 10: "Trusted"
- VLAN 20: "IoT"
- VLAN 30: "Old-Network"
- VLAN 40: "Test-VLAN"

**What happens when you run the playbook:**
```
✅ VLAN 10 (Trusted): no changes
✅ VLAN 20 (IoT): no changes
⚠️  WARNING: Deleting VLAN 30 'Old-Network' (not in playbook)
⚠️  WARNING: Deleting VLAN 40 'Test-VLAN' (not in playbook)
Result: 2 VLANs deleted
```

### Example Scenario - IP Groups

**Your configuration:**
```yaml
ip_groups:
  - name: "Trusted-Hosts"
    addresses: ["192.168.10.10/32", "192.168.10.20/32"]
```

**What exists in Omada:**
- IP Group: "Trusted-Hosts"
- IP Group: "Old-Group"
- IP Group: "Test-IPs"

**What happens when you run the playbook:**
```
✅ IP group 'Trusted-Hosts': no changes
⚠️  WARNING: Deleting IP group 'Old-Group' (not in playbook)
⚠️  WARNING: Deleting IP group 'Test-IPs' (not in playbook)
Result: 2 IP groups deleted
```

### Example Scenario - Firewall ACL Rules

**Your configuration:**
```yaml
firewall_acl_rules:
  - name: "IoT-Deny-To-Trusted"
    acl_type: gateway
    action: deny
    protocols: [all]
    source_type: network
    source_vlans: [20]
    destination_type: network
    destination_vlans: [10]
    direction:
      lan_to_lan: true
```

**What exists in Omada:**
- ACL: "IoT-Deny-To-Trusted"
- ACL: "Old-Block-Rule"
- ACL: "Test-Rule"

**What happens when you run the playbook:**
```
✅ ACL 'IoT-Deny-To-Trusted': no changes
⚠️  WARNING: Deleting ACL 'Old-Block-Rule' (not in playbook)
⚠️  WARNING: Deleting ACL 'Test-Rule' (not in playbook)
Result: 2 ACL rules deleted
```

### Example Scenario - WireGuard VPN

**Your configuration:**
```yaml
wireguard_servers:
  - name: "Main-VPN"
    listen_port: 51820
    private_key: "..."
    local_ip: "10.8.0.1"
    peers:
      - name: "laptop"
        public_key: "..."
        allowed_ips: ["192.168.10.0/24"]
```

**What exists in Omada:**
- WireGuard server: "Main-VPN" with peers: "laptop", "old-phone"
- WireGuard server: "Test-VPN" with peers: "test-peer"

**What happens when you run the playbook:**
```
✅ WireGuard server 'Main-VPN': no changes
✅ Peer 'laptop': no changes
⚠️  WARNING: Deleting peer 'old-phone' from server 'Main-VPN' (not in playbook)
Result: 1 peer deleted from Main-VPN
⚠️  WARNING: Deleting WireGuard server 'Test-VPN' (not in playbook)
Result: 1 WireGuard server deleted (with all its peers)
```

---

## Configuration

### Enable Auto-Cleanup (Default: Enabled)

In `inventories/production/group_vars/all.yml`:

```yaml
omada_auto_cleanup: true  # DANGER: Delete resources not in playbook
```

### Disable Auto-Cleanup (Safe Mode)

```yaml
omada_auto_cleanup: false  # Only create/update, never delete
```

---

## How It Works

### WiFi SSIDs

1. **Fetch** all existing SSIDs from Omada
2. **Compare** with SSIDs defined in playbook (`wifi:` section)
3. **Identify** SSIDs that exist in Omada but NOT in playbook
4. **Warn** you about what will be deleted
5. **Delete** each unmanaged SSID
6. **Report** how many were deleted

### VLANs/Networks

1. **Fetch** all existing networks from Omada
2. **Compare** with VLANs defined in playbook (`vlans:` section) by VLAN ID
3. **Identify** networks that exist in Omada but NOT in playbook
4. **Warn** you about what will be deleted (with VLAN IDs and names)
5. **Delete** each unmanaged network
6. **Report** how many were deleted

### IP Groups

1. **Fetch** all existing IP groups from Omada
2. **Compare** with IP groups defined in playbook (`ip_groups:` section) by name
3. **Identify** IP groups that exist in Omada but NOT in playbook
4. **Warn** you about what will be deleted (with group names)
5. **Delete** each unmanaged IP group
6. **Report** how many were deleted

### Firewall ACL Rules

1. **Fetch** all existing ACL rules from Omada
2. **Compare** with ACL rules defined in playbook (`firewall_acl_rules:` section) by name
3. **Identify** rules that exist in Omada but NOT in playbook
4. **Warn** you about what will be deleted (with rule names)
5. **Delete** each unmanaged ACL rule
6. **Report** how many were deleted

### Playbook Output - WiFi

```
TASK [wifi : Warning about SSIDs to be deleted]
ok: [omada-controller] => {
    "msg": [
        "WARNING: Auto-cleanup is enabled!",
        "The following SSIDs will be DELETED because they are not in the playbook:",
        "Guest-Network, Old-WiFi"
    ]
}

TASK [wifi : Delete SSIDs not defined in playbook (auto-cleanup)]
changed: [omada-controller] => (item=Guest-Network)
changed: [omada-controller] => (item=Old-WiFi)

TASK [wifi : Summary of cleanup operations]
ok: [omada-controller] => {
    "msg": "Deleted 2 SSID(s) not in playbook configuration"
}
```

### Playbook Output - VLANs

```
TASK [vlans : Warning about VLANs to be deleted]
ok: [omada-controller] => {
    "msg": [
        "WARNING: Auto-cleanup is enabled!",
        "The following VLANs will be DELETED because they are not in the playbook:",
        "Old-Network, Test-VLAN (VLAN IDs: 30, 40)"
    ]
}

TASK [vlans : Delete VLANs not defined in playbook (auto-cleanup)]
changed: [omada-controller] => (item=VLAN 30 - Old-Network)
changed: [omada-controller] => (item=VLAN 40 - Test-VLAN)

TASK [vlans : Summary of cleanup operations]
ok: [omada-controller] => {
    "msg": "Deleted 2 VLAN(s) not in playbook configuration"
}
```

### Playbook Output - IP Groups

```
TASK [ip_groups : Warning about IP groups to be deleted]
ok: [omada-controller] => {
    "msg": [
        "WARNING: Auto-cleanup is enabled!",
        "The following IP groups will be DELETED because they are not in the playbook:",
        "Old-Group, Test-IPs"
    ]
}

TASK [ip_groups : Delete IP groups not defined in playbook (auto-cleanup)]
changed: [omada-controller] => (item=Old-Group)
changed: [omada-controller] => (item=Test-IPs)

TASK [ip_groups : Summary of cleanup operations]
ok: [omada-controller] => {
    "msg": "Deleted 2 IP group(s) not in playbook configuration"
}
```

### Playbook Output - Firewall ACLs

```
TASK [firewall_policies : Warning about ACL rules to be deleted]
ok: [omada-controller] => {
    "msg": [
        "WARNING: Auto-cleanup is enabled!",
        "The following ACL rules will be DELETED because they are not in the playbook:",
        "Old-Block-Rule, Test-Rule"
    ]
}

TASK [firewall_policies : Delete ACL rules not defined in playbook (auto-cleanup)]
changed: [omada-controller] => (item=Old-Block-Rule)
changed: [omada-controller] => (item=Test-Rule)

TASK [firewall_policies : Summary of cleanup operations]
ok: [omada-controller] => {
    "msg": "Deleted 2 ACL rule(s) not in playbook configuration"
}
```

---

## Testing Auto-Cleanup

### Safe Test - WiFi SSIDs (Recommended First)

1. **Manually create a test SSID in Omada UI:**
   - Name: "TestSSID"
   - Any settings

2. **Run playbook in check mode (dry-run):**
   ```bash
   ansible-playbook playbooks/site.yml \
     -i inventories/production/hosts.yml \
     --vault-password-file ~/.ansible/vault_pass \
     --check
   ```

3. **Verify output shows what would be deleted**

4. **Run playbook normally to actually delete:**
   ```bash
   ansible-playbook playbooks/site.yml \
     -i inventories/production/hosts.yml \
     --vault-password-file ~/.ansible/vault_pass
   ```

5. **Check Omada UI - "TestSSID" should be gone**

### Safe Test - VLANs

1. **Manually create a test VLAN in Omada UI:**
   - VLAN ID: 99
   - Name: "TestVLAN"
   - Any settings

2. **Run playbook in check mode (dry-run):**
   ```bash
   ansible-playbook playbooks/site.yml \
     -i inventories/production/hosts.yml \
     --vault-password-file ~/.ansible/vault_pass \
     --check
   ```

3. **Verify output shows what would be deleted**

4. **Run playbook normally to actually delete:**
   ```bash
   ansible-playbook playbooks/site.yml \
     -i inventories/production/hosts.yml \
     --vault-password-file ~/.ansible/vault_pass
   ```

5. **Check Omada UI - "TestVLAN" should be gone**

### Safe Test - IP Groups

1. **Manually create a test IP group in Omada UI:**
   - Name: "TestIPGroup"
   - Add any IP address (e.g., "192.168.99.1/32")

2. **Run playbook in check mode (dry-run):**
   ```bash
   ansible-playbook playbooks/site.yml \
     -i inventories/production/hosts.yml \
     --vault-password-file ~/.ansible/vault_pass \
     --check
   ```

3. **Verify output shows what would be deleted**

4. **Run playbook normally to actually delete:**
   ```bash
   ansible-playbook playbooks/site.yml \
     -i inventories/production/hosts.yml \
     --vault-password-file ~/.ansible/vault_pass
   ```

5. **Check Omada UI - "TestIPGroup" should be gone**

### Safe Test - Firewall ACL Rules

**Note:** This requires a gateway device. If you don't have one, the firewall role will be skipped automatically.

1. **Manually create a test ACL rule in Omada UI:**
   - Name: "TestACL"
   - Any settings (e.g., deny IoT to Trusted)

2. **Run playbook in check mode (dry-run):**
   ```bash
   ansible-playbook playbooks/site.yml \
     -i inventories/production/hosts.yml \
     --vault-password-file ~/.ansible/vault_pass \
     --check
   ```

3. **Verify output shows what would be deleted**

4. **Run playbook normally to actually delete:**
   ```bash
   ansible-playbook playbooks/site.yml \
     -i inventories/production/hosts.yml \
     --vault-password-file ~/.ansible/vault_pass
   ```

5. **Check Omada UI - "TestACL" should be gone**

### What If Something Goes Wrong?

If auto-cleanup accidentally deletes something:

**For SSIDs:**
1. **SSIDs are easy to recreate** - just add them back to your config:
   ```yaml
   wifi:
     ssid: "RestoredNetwork"
     # ... settings ...
   ```

2. **Run playbook** - it will recreate the SSID

3. **No data loss** - WiFi settings can be reapplied

**For VLANs:**
1. **VLANs are easy to recreate** - just add them back to your config:
   ```yaml
   vlans:
     - id: 30
       name: "RestoredVLAN"
       subnet: "192.168.30.0/24"
       gateway: "192.168.30.1"
       dhcp_enabled: true
   ```

2. **Run playbook** - it will recreate the VLAN

3. **No data loss** - Network settings can be reapplied

**For IP Groups:**
1. **IP groups are easy to recreate** - just add them back to your config:
   ```yaml
   ip_groups:
     - name: "RestoredGroup"
       description: "Restored IP group"
       addresses:
         - "192.168.10.10/32"
         - "192.168.10.20/32"
   ```

2. **Run playbook** - it will recreate the IP group

3. **No data loss** - IP addresses can be reapplied

**For Firewall ACL Rules:**
1. **ACL rules are easy to recreate** - just add them back to your config:
   ```yaml
   firewall_acl_rules:
     - name: "RestoredRule"
       acl_type: gateway
       action: deny
       protocols: [all]
       source_type: network
       source_vlans: [20]
       destination_type: network
       destination_vlans: [10]
       direction:
         lan_to_lan: true
   ```

2. **Run playbook** - it will recreate the ACL rule

3. **No data loss** - Firewall rules can be reapplied

---

## Best Practices

### ✅ DO:
- Keep auto-cleanup enabled for true IaC
- Test in a dev/staging environment first
- Run playbook regularly to maintain consistency
- Keep your playbook config in git for versioning
- Review warnings before confirming deletions

### ❌ DON'T:
- Manually create SSIDs, VLANs, IP groups, or ACL rules in Omada UI (they'll be deleted!)
- Share Omada controller with others who create resources manually
- Run playbook without reviewing changes first
- Forget what's in your configuration file

---

## Disabling Cleanup for Specific Runs

### Skip cleanup tasks temporarily:

```bash
ansible-playbook playbooks/site.yml \
  -i inventories/production/hosts.yml \
  --vault-password-file ~/.ansible/vault_pass \
  --skip-tags cleanup
```

This will create/update resources but skip deletion.

---

## Future Enhancements

### Planned:
- [ ] Dry-run mode that shows what would be deleted without doing it (check mode partially works)
- [ ] Whitelist certain SSIDs from auto-deletion
- [ ] Backup before deletion

### Not Planned:
- Firewall ACLs (not supported on your setup)
- Port forwarding (not supported on your setup)

---

## Migration Guide

### Migrating to Auto-Cleanup

If you have existing SSIDs and VLANs in Omada:

**For SSIDs:**
1. **List all SSIDs** currently in Omada UI

2. **Add them all to your playbook config** (even temporary ones):
   ```yaml
   wifi:
     ssid: "Home"  # Currently only supports single SSID
   ```

3. **Run playbook** - should show "no changes"

4. **Remove SSIDs you don't want** from config

5. **Run playbook** - those SSIDs will be deleted

**For VLANs:**
1. **List all VLANs** currently in Omada UI

2. **Add them all to your playbook config**:
   ```yaml
   vlans:
     - id: 10
       name: "Trusted"
       # ... settings ...
     - id: 20
       name: "IoT"
       # ... settings ...
     - id: 30
       name: "Guests"
       # ... settings ...
   ```

3. **Run playbook** - should show "no changes"

4. **Remove VLANs you don't want** from config

5. **Run playbook** - those VLANs will be deleted

**For IP Groups:**
1. **List all IP groups** currently in Omada UI

2. **Add them all to your playbook config**:
   ```yaml
   ip_groups:
     - name: "Trusted-Hosts"
       addresses:
         - "192.168.10.10/32"
         # ... all IPs ...
     - name: "External-Services"
       addresses:
         - "8.8.8.8/32"
         # ... all IPs ...
   ```

3. **Run playbook** - should show "no changes"

4. **Remove IP groups you don't want** from config

5. **Run playbook** - those IP groups will be deleted

**For Firewall ACL Rules:**
1. **List all ACL rules** currently in Omada UI (gateway/switch/EAP ACLs)

2. **Add them all to your playbook config**:
   ```yaml
   firewall_acl_rules:
     - name: "IoT-Deny-To-Trusted"
       acl_type: gateway
       action: deny
       protocols: [all]
       source_type: network
       source_vlans: [20]
       destination_type: network
       destination_vlans: [10]
       direction:
         lan_to_lan: true
     - name: "Guests-Deny-To-LANs"
       acl_type: gateway
       action: deny
       # ... settings ...
   ```

3. **Run playbook** - should show "no changes"

4. **Remove ACL rules you don't want** from config

5. **Run playbook** - those rules will be deleted

---

## Comparison: Auto-Cleanup vs Manual

| Aspect | Auto-Cleanup ON | Auto-Cleanup OFF |
|--------|-----------------|------------------|
| **Philosophy** | Infrastructure-as-Code | Assistive tool |
| **Omada state** | Matches playbook exactly | May drift over time |
| **Manual changes** | Get deleted | Stay forever |
| **Safety** | Dangerous ⚠️ | Safe ✅ |
| **Use case** | Automated environments | Shared/manual mgmt |

---

## Troubleshooting

### "It deleted my production SSID/VLAN/IP group/ACL rule!"

**Prevention:** Set `omada_auto_cleanup: false` in production until tested

**Recovery for SSIDs:**
1. Add the SSID back to your config
2. Run the playbook
3. SSID will be recreated

**Recovery for VLANs:**
1. Add the VLAN back to your config
2. Run the playbook
3. VLAN will be recreated

**Recovery for IP Groups:**
1. Add the IP group back to your config
2. Run the playbook
3. IP group will be recreated

**Recovery for Firewall ACL Rules:**
1. Add the ACL rule back to your config
2. Run the playbook
3. ACL rule will be recreated

### "It's not deleting anything"

Check:
1. Is `omada_auto_cleanup: true`?
2. Are SSIDs/VLANs/IP groups/ACL rules listed correctly in config?
3. Check playbook output for warnings
4. Run with `-vvv` for debug output

### "I want to exclude one SSID/VLAN/IP group/ACL rule from cleanup"

**Current workaround:** Add it to your config
**Future:** Whitelist feature (not yet implemented)

---

## Summary

Auto-cleanup provides true Infrastructure-as-Code by ensuring your Omada controller state exactly matches your configuration.

**It's powerful but dangerous** - use with caution and test thoroughly before enabling in production!
