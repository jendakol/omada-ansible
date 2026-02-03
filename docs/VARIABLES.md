### Variables reference and examples

All variables live under `group_vars/all.yml` (or per‑site). Secrets should be stored in Ansible Vault.

#### Controller
```yaml
omada_controller_url: "https://omada.example.local"
omada_site: "Default"
omada_username: "{{ vault_omada_username }}"
omada_password: "{{ vault_omada_password }}"
verify_ssl: true
```

#### VLANs / Networks
```yaml
# Minimal configuration (using defaults)
vlans:
  - id: 10
    name: "Trusted"
    subnet: "192.168.10.0/24"
    dhcp_enabled: true

  - id: 20
    name: "IoT"
    subnet: "192.168.20.0/24"
    dhcp_enabled: true

# Full configuration (with optional fields)
vlans:
  - id: 10
    name: "Trusted"
    subnet: "192.168.10.0/24"
    dhcp_enabled: true
    dhcp_range_start: "192.168.10.101"  # Optional, default: .1
    dhcp_range_end: "192.168.10.254"    # Optional, default: .254
    dns_servers:                         # Optional, default: auto DNS
      - "8.8.8.8"
      - "8.8.4.4"
    lease_time: 300                      # Optional, default: 120 minutes

# Notes:
# - Subnet format: Both "192.168.10.0/24" and "192.168.10.1/24" work
#   The role converts either format to gatewaySubnet "192.168.10.1/24" for the API
#   Recommended: use standard network notation (192.168.10.0/24)
# - DHCP range defaults to .1 - .254 if not specified
# - DNS servers: if specified, uses manual DNS mode; if omitted, uses controller's auto DNS
# - Lease time in minutes, default 120
```

#### Wi‑Fi (single SSID, default VLAN Guests)
```yaml
wifi:
  ssid: "Home"
  default_vlan: 30
  security:
    mode: wpa2          # wpa2 | wpa3 | wpa2_wpa3
    passphrase: "{{ vault_wifi_passphrase }}"
  client_isolation: true
```

#### Firewall policies and exceptions
```yaml
firewall_policies:
  trusted:
    allow_any: true
  iot:
    deny_to_lans: true
    deny_to_wan: true
    allow_internet_exceptions:
      # Examples (disabled until you fill real identifiers)
      - name: HAOS
        selector: { mac: "AA:BB:CC:DD:EE:FF" }
      - name: Vacuum
        selector: { ip: "192.168.20.50" }
      - name: TV
        selector: { ip: "192.168.20.60" }
    allow_to_trusted:
      - name: haos_to_db
        source: { ip: "192.168.20.X" }
        dest:   { ip: "192.168.10.Y", ports: [5432] }
        proto: tcp
    allow_mdns_to_trusted: true
    allow_cast_to_trusted: true
  guests:
    deny_to_lans: true
    allow_to_wan: true
```

#### WireGuard (router‑hosted)
```yaml
wireguard:
  enabled: false
  listen_port: 51820
  subnet: "10.8.0.0/24"
  peers:
    - name: laptop
      public_key: "<fill>"
      allowed_ips: ["10.8.0.2/32"]
```

#### PPSK (Private Pre-Shared Key) Profiles
```yaml
ppsk_profiles:
  - name: "Home-PPSK"
    entries:
      - name: "Trusted-Devices"
        psk: "TrustedPass123!"
        vlan: "10"
      - name: "IoT-Devices"
        psk: "IoTPass123!"
        vlan: "20"
      - name: "Guest-Access"
        psk: "GuestPass123!"
        vlan: "30"
```

#### WiFi with PPSK
```yaml
wifi_ssids:
  # Regular SSID with single password
  - name: "MyNetwork"
    security: "wpa2_personal"
    password: "wifi-password"
    vlan: 10

  # PPSK SSID with multiple passwords
  - name: "MyNetwork-PPSK"
    ppsk_profile: "Home-PPSK"  # Different passwords assign to different VLANs
    enabled: true
    guest_network: true
```

#### IP Groups
```yaml
ip_groups:
  # Using device references (recommended)
  - name: "Internal-Servers"
    description: "Critical internal servers"
    devices:
      - server-01
      - nas-storage
      - home-assistant

  # Using direct addresses (for external IPs)
  - name: "DNS-servers"
    description: "Public DNS servers"
    addresses:
      - "8.8.8.8/32"
      - "1.1.1.1/32"

  # Mixed: both devices and addresses
  - name: "Management"
    description: "Management devices and external admin IPs"
    devices:
      - server-01
    addresses:
      - "203.0.113.10/32"
```

#### NAT Port Forwarding
```yaml
port_forward_rules:
  # Default: applies to all active WANs
  - name: "web-server-http"
    enabled: true
    external_port: "80"
    forward_device: "server-01"  # Device from infra_devices.yml (recommended)
    forward_port: "8080"
    protocol: tcp
    description: "Public HTTP - accessible from all WANs"

  # Specific WAN (single)
  - name: "game-server"
    enabled: true
    external_port: "27015"
    forward_device: "server-01"
    forward_port: "27015"
    protocol: udp
    wan_interfaces: ["WAN2"]  # Apply to specific WAN
    description: "Game server on secondary WAN"

  # Multiple WANs
  - name: "multi-wan-service"
    enabled: true
    external_port: "8443"
    forward_device: "server-01"
    forward_port: "443"
    protocol: tcp
    wan_interfaces: ["SFP WAN/LAN1", "WAN2"]  # Multiple WANs
    description: "Service accessible via both WANs"
```

#### Multicast/Bonjour forwarding
```yaml
multicast_forwarding:
  enabled: true
  services: [mdns]
```
