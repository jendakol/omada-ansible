# Description

- Omada SDN
    - ER7602
    - EAP650-Desktop
    - EAP225-Outdoor
- Omada controller (6.0) in Docker, accessible via HTTPS API
- Ansible
  - runs on the local server
  - login to OC via https://omada.home.jenda.eu

## VLAN

- Trusted, ID = 10, DHCP 192.168.10.0/24 (gateway .1)
    - Full visibility of all devices across all VLANs
    - Full access to the internet and to all VLANs
    - Including infrastructure (router, AP)

- IoT, ID = 20, DHCP 192.168.20.0/24 (gateway .1)
    - Isolation of devices (no traversal to other VLANs)
        - Ability to have exceptions like for HAOS:
            - Everyone must have access to HAOS, and HAOS must have access to everyone (within the IoT VLAN)
            - HAOS must have access to a specific device (and specific ports) in Trusted (DB connection)
        - Exception: allow mDNS to pass through to the Trusted VLAN; Miracast/AirPlay/Google Cast must work (mDNS
          repeater)
    - No internet access; ability to have exceptions

- Guests, ID = 30, DHCP 192.168.30.0/24 (gateway .1)
    - Isolation of devices (no traversal to other VLANs)
    - Full internet access

- Every newly connected device goes to the Guests VLAN by default, with the option to manually move it to other VLANs (
  not handled by Ansible)

## Wi‑Fi

- A single SSID for all devices (and handling of all VLANs as described above)

## WireGuard

- VPN connection from WAN
- Configured directly on the router, via Omada Controller
- IP range 10.8.0.0/24
- Firewall rules to allow VPN clients to traversal everywhere

## Other

- DHCP assignments ("reservations")
- Ability to have Port forwarding from WAN to Trusted (public web server)
