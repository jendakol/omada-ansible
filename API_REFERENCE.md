# Omada SDN API Reference

This file contains anonymized API request/response examples for reference.

## Authentication

### Get Controller Info
```
GET /api/info
Response: {
  "result": {
    "omadacId": "<controller-id>",
    "controllerVer": "6.0.0.25"
  }
}
```

### Login
```
POST /{omadacId}/api/v2/login
Body: {
  "username": "admin",
  "password": "password"
}

Response Cookies:
- TPOMADA_SESSIONID: <session-id>
- csrfToken: <csrf-token>

Response Body: {
  "result": {
    "token": "<auth-token>"
  }
}
```

## Networks (VLANs)

### List Networks
```
GET /api/v2/sites/{siteId}/setting/lan/networks?currentPage=1&currentPageSize=50
```

## WAN

### Get WAN Networks
```
GET /api/v2/sites/{siteId}/setting/wan/networks

Response: {
  "result": {
    "portUuids": ["1_<uuid>"],
    "wanPortSettings": [...]
  }
}
```

## WiFi (WLAN)

### List WLANs
```
GET /api/v2/sites/{siteId}/setting/wlans?currentPage=1&currentPageSize=50
```

### List SSIDs
```
GET /api/v2/sites/{siteId}/setting/wlans/{wlanId}/ssids?currentPage=1&currentPageSize=50
```

### Update SSID with VLAN
```
PATCH /api/v2/sites/{siteId}/setting/wlans/{wlanId}/ssids/{ssidId}

Body: {
  "name": "Home",
  "vlanSetting": {
    "mode": 1,
    "customConfig": {
      "customMode": 0,
      "lanNetworkVlanIds": {
        "<network-id>": [30]
      }
    }
  }
}
```

### Update SSID with PPSK
```
PATCH /api/v2/sites/{siteId}/setting/wlans/{wlanId}/ssids/{ssidId}

Body: {
  "name": "MyNetwork",
  "band": 3,  # 1=2.4GHz, 2=5GHz, 3=2.4+5GHz, 7=2.4+5+6GHz (PPSK doesn't support 6GHz)
  "guestNetEnable": true,
  "security": 4,  # 4 = PPSK (WPA2/WPA3-Personal with multiple passwords)
  "broadcast": true,
  "vlanSetting": {
    "mode": 0  # Fixed VLAN not used with PPSK
  },
  "pskSetting": {
    "encryptionPsk": 3,  # AES
    "versionPsk": 2,  # WPA2
    "gikRekeyPskEnable": false
    # No securityKey - passwords come from PPSK profile
  },
  "ppskSetting": {
    "ppskProfileId": "<ppsk-profile-id>",
    "macFormat": 2,
    "type": 0
  },
  "pmfMode": 3,  # Protected Management Frames (required for PPSK)
  "rateLimit": {
    "downLimitEnable": false,
    "upLimitEnable": false
  },
  "ssidRateLimit": {
    "downLimitEnable": false,
    "upLimitEnable": false
  },
  "wlanScheduleEnable": false,
  "rateAndBeaconCtrl": {
    "rate2gCtrlEnable": false,
    "rate5gCtrlEnable": false,
    "rate6gCtrlEnable": false
  },
  "macFilterEnable": false,
  "wlanId": "",
  "enable11r": false,
  "multiCastSetting": {
    "multiCastEnable": true,
    "arpCastEnable": true,
    "filterEnable": false,
    "ipv6CastEnable": true,
    "channelUtil": 100
  },
  "greEnable": false,
  "prohibitWifiShare": false,
  "mloEnable": false
}
```

## PPSK (Private Pre-Shared Key) Profiles

### List PPSK Profiles
```
GET /api/v2/sites/{siteId}/setting/profiles/ppsk?type=0

Response: {
  "errorCode": 0,
  "msg": "Success.",
  "result": [
    {
      "id": "<ppsk-profile-id>",
      "profileName": "Home-PPSK",
      "ssid": ["MyNetwork"],  # SSIDs using this profile
      "type": 0,
      "resource": 0
    }
  ]
}
```

### Create PPSK Profile
```
POST /api/v2/sites/{siteId}/setting/profiles/ppsk

Body: {
  "profileName": "Home-PPSK",
  "ppsk": [
    {
      "name": "Trusted-Devices",
      "psk": "TrustedPass123!",
      "mac": "",  # Usually empty, can restrict to specific MAC
      "vlan": 10  # VLAN ID (integer) - devices using this password go to this VLAN
    },
    {
      "name": "IoT-Devices",
      "psk": "IoTPass123!",
      "mac": "",
      "vlan": 20
    },
    {
      "name": "Guest-Access",
      "psk": "GuestPass123!",
      "mac": ""
      # No vlan - uses SSID default VLAN
    }
  ],
  "type": 0
}

Response: {
  "errorCode": 0,
  "msg": "Success.",
  "result": {
    "id": "<ppsk-profile-id>",
    "profileName": "Home-PPSK",
    ...
  }
}
```

### Update PPSK Profile
```
POST /api/v2/sites/{siteId}/setting/profiles/ppsk/{ppskProfileId}

Body: {
  "profileName": "Home-PPSK",
  "ppsk": [
    {
      "name": "Trusted-Devices",
      "psk": "TrustedPass123!",
      "mac": "",
      "vlan": 10
    },
    {
      "name": "IoT-Devices",
      "psk": "IoTPass123!",
      "mac": "",
      "vlan": 20
    }
  ],
  "type": 0,
  "resource": 0  # Required for updates
}
```

### Delete PPSK Profile
```
DELETE /api/v2/sites/{siteId}/setting/profiles/ppsk/{ppskProfileId}
```

**Notes:**
- PPSK allows one SSID with multiple passwords, each assigning to a different VLAN
- `security: 4` indicates PPSK mode on the SSID
- PPSK only supports 2.4GHz and 5GHz (not 6GHz)
- `pmfMode: 3` (Protected Management Frames) is required for PPSK
- `mac` field usually empty - used to restrict specific MAC addresses to certain passwords
- `vlan` field is integer VLAN ID - if omitted, uses SSID's default VLAN
- Password requirements: minimum 8 characters, WPA2/WPA3 standards
- Each entry in `ppsk` array represents a different password with its own VLAN assignment

## IP Groups

### List IP Groups
```
GET /api/v2/sites/{siteId}/setting/profiles/groups/0?currentPage=1&currentPageSize=50  # IPv4
GET /api/v2/sites/{siteId}/setting/profiles/groups/3?currentPage=1&currentPageSize=50  # IPv6
```

### Create IP Group
```
POST /api/v2/sites/{siteId}/setting/profiles/groups

Body (IPv4):
{
  "name": "Group-Name",
  "type": 0,
  "ipList": [
    {"ip": "192.168.1.1", "mask": "32", "description": ""}
  ]
}

Body (IPv6):
{
  "name": "Group-Name",
  "type": 3,
  "ipv6List": [
    {"ip": "2001:db8::1", "prefix": "128", "description": ""}
  ]
}
```

### Update IP Group
```
PATCH /api/v2/sites/{siteId}/setting/profiles/groups/0/{groupId}  # IPv4
PATCH /api/v2/sites/{siteId}/setting/profiles/groups/3/{groupId}  # IPv6
```

## IP-Port Groups

IP-Port groups combine IP addresses with port numbers for granular firewall control (type=1).

### List IP-Port Groups
```
GET /api/v2/sites/{siteId}/setting/profiles/groups?type=1&currentPage=1&currentPageSize=50
```

### Get IP-Port Group (Example Response)
```json
{
  "groupId": "695fde26312aea18bfb13fa1",
  "site": "695570eb836e41425b5c9738",
  "name": "dns group",
  "ipList": [
    {
      "ip": "192.168.10.11",
      "mask": 32,
      "description": ""
    }
  ],
  "portType": 0,
  "portList": ["53"],
  "portMaskList": [],
  "count": 2,
  "type": 1,
  "resource": 0
}
```

### Create IP-Port Group (No IPs, Single Port)
```
POST /api/v2/sites/{siteId}/setting/profiles/groups

Body:
{
  "name": "tst",
  "type": 1,
  "ipList": [],
  "ipv6List": null,
  "macAddressList": null,
  "portList": ["53"],
  "countryList": null,
  "description": "",
  "portType": 0,
  "domainNamePort": null,
  "ouiList": null,
  "count": 0
}
```

### Create IP-Port Group (Multiple IPs, Single Port)
```
POST /api/v2/sites/{siteId}/setting/profiles/groups

Body:
{
  "name": "tst2",
  "type": 1,
  "ipList": [
    {
      "ip": "192.168.10.11",
      "mask": "32",
      "key": 1767904271724,
      "description": ""
    },
    {
      "ip": "192.168.20.11",
      "mask": "32",
      "key": 1767904282938,
      "description": ""
    }
  ],
  "ipv6List": null,
  "macAddressList": null,
  "portList": ["53"],
  "countryList": null,
  "description": "",
  "portType": 0,
  "domainNamePort": null,
  "ouiList": null,
  "count": 0
}
```

### Update IP-Port Group
```
PATCH /api/v2/sites/{siteId}/setting/profiles/groups/1/{groupId}

Body:
{
  "name": "tst3",
  "type": 1,
  "resource": 0,
  "ipList": [
    {
      "ip": "192.168.10.11",
      "mask": 32,
      "description": "",
      "key": 1767904811339
    },
    {
      "ip": "192.168.20.11",
      "mask": 32,
      "description": "",
      "key": 1767904811340
    }
  ],
  "ipv6List": null,
  "macAddressList": null,
  "portList": ["53", "54", "55"],
  "countryList": null,
  "portType": 0,
  "domainNamePort": null,
  "ouiList": null,
  "count": 4
}
```

**Notes:**
- `type: 1` indicates IP-Port group (vs type: 0 for IP-only group)
- `portType: 0` indicates TCP/UDP ports
- `count` in listing = number of IP ranges + number of ports
- `count` in request can be 0 (controller calculates it)
- `key` field in `ipList` items is required for updates (timestamp-based)

## Firewall ACLs

### List ACLs
```
GET /api/v2/sites/{siteId}/setting/firewall/acls?currentPage=1&currentPageSize=50&type=0  # Gateway
GET /api/v2/sites/{siteId}/setting/firewall/acls?currentPage=1&currentPageSize=50&type=1  # Switch
GET /api/v2/sites/{siteId}/setting/firewall/acls?currentPage=1&currentPageSize=50&type=2  # EAP
```

### Create ACL (Basic - Network to Network)
```
POST /api/v2/sites/{siteId}/setting/firewall/acls?type=0

Body: {
  "name": "Rule-Name",
  "type": "0",
  "policy": "1",  # 0=deny, 1=allow
  "protocols": [256],  # 256=all
  "sourceType": "0",  # 0=network
  "sourceIds": ["<network-id>"],
  "destinationType": "0",
  "destinationIds": ["<network-id>"],
  "status": true,
  "direction": {
    "lanToLan": true,
    "lanToWan": false
  }
}
```

### Create Gateway ACL with IP-Port Group (LAN/WAN)
```
POST /api/v2/sites/{siteId}/setting/firewall/acls

Body: {
  "name": "tst-gw",
  "status": true,
  "policy": 0,  # 0=deny, 1=allow
  "protocols": [256],  # 256=all protocols
  "sourceType": 0,  # 0=network
  "sourceIds": ["69557123836e41425b5c9768"],  # Network ID
  "destinationType": 2,  # 2=IP-Port group
  "destinationIds": ["696019fb312aea18bfb1462d"],  # IP-Port group ID
  "direction": {
    "wanInIds": [],
    "vpnInIds": [],
    "lanToWan": true,
    "lanToLan": false
  },
  "type": 0,  # 0=Gateway ACL
  "ipSec": 0,
  "stateMode": 0,
  "customAclOsws": [],
  "syslog": false,
  "customAclStacks": []
}
```

**Important:** Gateway ACLs only support IP groups and IP-Port groups for **LAN-to-WAN** traffic. For LAN-to-LAN rules, use whole networks or Switch/EAP ACL types.

### Create Switch ACL with IP-Port Group (IP Group to IP-Port Group)
```
POST /api/v2/sites/{siteId}/setting/firewall/acls

Body: {
  "name": "tst_sw",
  "status": true,
  "policy": 0,
  "protocols": [256],
  "sourceType": 1,  # 1=IP group (type=0)
  "sourceIds": ["695570eb836e41425b5c9752"],  # IP group ID
  "destinationType": 2,  # 2=IP-Port group (type=1)
  "destinationIds": ["696019fb312aea18bfb1462d"],  # IP-Port group ID
  "bindingType": 0,
  "customAclPorts": [],
  "type": 1,  # 1=Switch ACL
  "biDirectional": false,
  "ipSec": 0,
  "customAclOsws": [],
  "syslog": false,
  "customAclStacks": [],
  "etherType": {
    "enable": false
  }
}
```

### Create EAP ACL with IP-Port Groups
```
POST /api/v2/sites/{siteId}/setting/firewall/acls

Body: {
  "name": "tst_eap",
  "status": true,
  "policy": 0,
  "protocols": [256],
  "sourceType": 2,  # 2=IP-Port group (type=1)
  "sourceIds": ["696019fb312aea18bfb1462d"],  # IP-Port group ID
  "destinationType": 2,  # 2=IP-Port group (type=1)
  "destinationIds": ["695fde26312aea18bfb13fa1"],  # IP-Port group ID
  "type": 2,  # 2=EAP ACL
  "ipSec": 0,
  "customAclOsws": [],
  "syslog": false,
  "customAclStacks": []
}
```

**Source/Destination Type Values:**
- `0` = Network (VLAN)
- `1` = IP Group (group type=0)
- `2` = IP-Port Group (group type=1)

**ACL Type Values:**
- `0` = Gateway ACL (inter-VLAN routing, LAN-to-WAN)
- `1` = Switch ACL (switch-level filtering)
- `2` = EAP ACL (access point filtering)

## Port Forwarding

### List Port Forwards
```
GET /api/v2/sites/{siteId}/setting/transmission/portForwardings?currentPage=1&currentPageSize=50
```

### Create Port Forward
```
POST /api/v2/sites/{siteId}/setting/transmission/portForwardings

Body: {
  "name": "Rule-Name",
  "externalPort": "443",
  "forwardIp": "192.168.10.100",
  "forwardPort": "4443",
  "protocol": 1,  # 0=ALL, 1=TCP, 2=UDP
  "status": true,
  "dMZ": false,
  "from": 0,
  "interfaceWanPortId": ["1_<uuid>"],
  "virtualWanId": []
}
```

### Update Port Forward
```
PUT /api/v2/sites/{siteId}/setting/transmission/portForwardings/{id}
```

### Delete Port Forward
```
DELETE /api/v2/sites/{siteId}/setting/transmission/portForwardings/{id}
```

## DHCP Reservations

### List DHCP Reservations
```
GET /api/v2/sites/{siteId}/setting/service/dhcp?currentPage=1&currentPageSize=10&searchKey=

Response: {
  "result": {
    "data": [
      {
        "id": "<reservation-id>",
        "netId": "<network-id>",
        "mac": "AA-BB-CC-DD-EE-FF",
        "ip": "192.168.10.100",
        "clientName": "hostname",
        "description": "Device description",
        "status": true,
        "netName": "VLAN-Name",
        "options": []
      }
    ]
  }
}
```

### Create DHCP Reservation
```
POST /api/v2/sites/{siteId}/setting/service/dhcp

Body: {
  "netId": "<network-id>",
  "mac": "AA-BB-CC-DD-EE-FF",
  "clientName": "hostname",
  "ip": "192.168.10.100",
  "ipStart": 3232238080,  # DHCP pool start (integer)
  "ipEnd": 3232238335,    # DHCP pool end (integer)
  "description": "Device description",
  "status": true,
  "options": []
}
```

### Update DHCP Reservation
```
PUT /api/v2/sites/{siteId}/setting/service/dhcp/{mac}

Body: {
  "netId": "<network-id>",
  "mac": "AA-BB-CC-DD-EE-FF",
  "clientName": "hostname",
  "ip": "192.168.10.100",
  "ipStart": 3232238080,
  "ipEnd": 3232238335,
  "description": "Device description",
  "status": true,
  "options": []
}
```

### Delete DHCP Reservation
```
DELETE /api/v2/sites/{siteId}/setting/service/dhcp/{mac}
```

**Notes:**
- MAC address format: Dashes (AA-BB-CC-DD-EE-FF), not colons
- MAC address in URL for update/delete operations
- ipStart/ipEnd: Integer representation of DHCP pool range
  - Example: 192.168.10.1 = 3232238080
  - Calculation: (192 << 24) + (168 << 16) + (10 << 8) + 1

## Sites

### Create Site
```
POST /api/v2/sites

Body: {
  "name": "Test-Site",
  "region": "Czechia",
  "timeZone": "Europe/Prague",
  "scenario": "Home",
  "deviceAccountSetting": {
    "username": "device",
    "password": "SecurePassword123!"
  },
  "tagIds": [],
  "supportES": false,
  "supportL2": true
}

Response: {
  "errorCode": 0,
  "msg": "Success.",
  "result": {
    "id": "<site-id>",
    "name": "Test-Site",
    ...
  }
}
```

### Delete Site
```
DELETE /api/v2/sites/{siteId}
```

**Notes:**
- Device account credentials required for site creation
- Password must meet complexity requirements (mixed case, numbers, symbols)
- `supportL2`: Layer 2 support (switches)
- `supportES`: Enterprise support

## WireGuard VPN

### List WireGuard Servers
```
GET /api/v2/sites/{siteId}/setting/vpn/wireguard?currentPage=1&currentPageSize=50
```

## mDNS Forwarding Rules

### List mDNS Rules
```
GET /api/v2/sites/{siteId}/setting/service/mdns?currentPage=1&currentPageSize=10

Response: {
  "errorCode": 0,
  "msg": "Success.",
  "result": {
    "totalRows": 1,
    "data": [
      {
        "id": "<rule-id>",
        "name": "mDNS forward",
        "status": true,
        "type": 1,
        "osg": {
          "profileIds": ["buildIn-1", "buildIn-2", ...],
          "serviceNetworks": ["<network-id>"],
          "clientNetworks": ["<network-id>", "<network-id>"]
        },
        "resource": 0
      }
    ],
    "apRuleNum": 0,
    "osgRuleNum": 1,
    "apRuleLimit": 16,
    "osgRuleLimit": 20
  }
}
```

### Create mDNS Rule
```
POST /api/v2/sites/{siteId}/setting/service/mdns

Body: {
  "name": "mDNS forward",
  "status": true,
  "type": 1,
  "osg": {
    "profileIds": ["buildIn-1", "buildIn-2", "buildIn-3", "buildIn-4", "buildIn-5",
                   "buildIn-6", "buildIn-7", "buildIn-8", "buildIn-9", "buildIn-10"],
    "serviceNetworks": ["<network-id>"],
    "clientNetworks": ["<network-id>", "<network-id>"]
  }
}
```

### Update mDNS Rule
```
PUT /api/v2/sites/{siteId}/setting/service/mdns/{ruleId}

Body: Same structure as create
```

### Delete mDNS Rule
```
DELETE /api/v2/sites/{siteId}/setting/service/mdns/{ruleId}
```

**Notes:**
- mDNS is configured as rules (similar to ACL rules)
- `type`: 1 = Gateway (OSG)
- `profileIds`: Built-in service profiles (buildIn-1 to buildIn-10)
  - Common services: AirPlay, Chromecast, Spotify Connect, etc.
- `serviceNetworks`: Network IDs where services are located (e.g., IoT VLAN with smart devices)
- `clientNetworks`: Network IDs where clients are located (e.g., Trusted/Guests VLANs with phones/laptops)
- Forwards mDNS/Bonjour traffic between client and service networks

## Firewall ACL - Reorder Rules

**Endpoint:** `POST /api/v2/sites/{site}/cmd/acls/modifyIndex`

**Description:** Reorder firewall ACL rules by updating their index positions. Rules are evaluated in order by index (lower index = evaluated first).

**Request Body:**
```json
{
  "indexes": {
    "rule_id_1": new_index,
    "rule_id_2": new_index
  },
  "type": 0  // 0=Gateway, 1=Switch, 2=EAP
}
```

**Example - Reorder two rules (swap positions 8 and 9):**
```json
{
  "indexes": {
    "6958cf702471ae0032f6d142": 8,
    "6957c776836e41425b5cb7a7": 9
  },
  "type": 0
}
```

**Notes:**
- The `indexes` object maps rule ID → desired index position
- Index starts at 1 (not 0)
- You can update multiple rules in one call
- Only rules included in the payload will be reordered
- Rules not in the payload keep their current index
- Use this after creating/updating rules to enforce correct evaluation order

