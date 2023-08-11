[![Build Status](https://travis-ci.org/bibigon812/bibigon812-quagga.svg?branch=master)](https://travis-ci.org/bibigon812/bibigon812-quagga)

## Table of Contents

1. [Module Description](#module-description)
1. [Notice](#notice)
1. [Quick Start](#quick-start)
1. [Zebra Options](#zebra-options)
    * [SNMP](#snmp)
    * [Forwarding](#forwarding)
    * [Interfaces](#interfaces)
    * [Routes](#routes)
    * [Access-Lists](#access-lists)
    * [Prefix Lists](#prefix-lists)
    * [Route Maps](#route-maps)
1. [BGP](#bgp)
    * [BGP SNMP](#bgp-snmp)
    * [BGP Router](#bgp-router)
    * [BGP Address Families](#bgp-address-families)
    * [BGP Peers](#bgp-peers)
    * [BGP AS-Paths](#bgp-as-paths)
    * [BGP Community Lists](#bgp-community-lists)
1. [OSPF](#ospf)
    * [OSPF SNMP](#ospf-snmp)
    * [OSPF Router](#ospf-router)
    * [OSPF Areas](#ospf-areas)
    * [OSPF Interfaces](#ospf-interfaces)
1. [PIM](#pim)
    * [PIM SNMP](#pim-snmp)
    * [PIM Router](#pim-router)
    * [PIM Interfaces](#pim-interfaces)

## Module Description

This module provides management of network protocols without restarting
services. All resources make changes to the configuration of services using
commands, as if you are doing this through the CLI.

## Notice

- If you use SELinux set the sebool for Quagga:

```bash
setsebool zebra_write_config on
```

- If you have over 500k routes on CentOS set `UseDNS no` in `/etc/ssh/sshd_config`
- If you have the FullView on CentOS turn off `NetworkManager`.

```bash
systemctl stop NetworkManager
systemctl mask NetworkManager
```

- Use the default value for the `default_ipv4_unicast` property of the `quagga_bgp_router` resource type.
- The correct way to delete route-map or prefix-list rules is to use the `ensure: absent`.

```
quagga::zebra::route_maps:
  ROUTE_MAP_IN:
    rules:
      1:
        ensure: absent
        action: deny
        match: ip address prefix-list ADVERTISED_PREFIXES
```

## Quick Start

Include with default parameters:

```puppet
include quagga
```

## Zebra Options

### SNMP

```yaml
quagga::zebra::agentx: false
```

### Forwarding

```yaml
quagga::zebra::global_opts:
  ip_forwarding: true
  ipv6_forwarding: true
```

### Interfaces

```yaml
quagga::zebra::interfaces:
  eth0:
    ip_address:
      - 10.0.0.1/24
  lo:
    ip_address:
      - 10.255.255.1/32
      - 172.16.255.1/32
```

### Routes

The prefix and the nexthop are namevars.

```yaml
quagga::zebra::routes:
  192.168.0.0/24:
    ensure: present
    nexthop: 10.0.0.100
    distance: 250
  192.168.1.0/24 Null0:
    ensure: present
    distance: 250
  192.168.1.0/24 10.0.0.100:
    ensure: present
    option: reject
    distance: 200
```

### Access-Lists

- standard: 1-99, 1300-1999
- extended: 100-199, 2000-2699
- zebra: [[:alpha:]]+

```yaml
quagga::zebra::access_lists:
  1:
    remark: Standard access-list
    rules:
      - permit 127.0.0.1
      - deny any
  100:
    remark: Extended access-list
    rules:
      - permit ip 10.0.0.0 0.0.0.255 any
      - permit ip any 10.0.0.0 0.0.0.255
      - deny ip any any
  zebra_list:
    remark: Zebra access-list
    rules:
      - permit 10.0.0.0/24
      - deny any
```

## Prefix Lists

```yaml
quagga::zebra::prefix_lists:
  CONNECTED_PREFIXES:
    rules:
      500:
        action: permit
        le: 32
        prefix: 10.255.255.0/24
  OSPF_PREFIXES:
    rules:
      10:
        action: permit
        prefix: 172.16.255.0/24
```

## Route Maps

```yaml
quagga::zebra::route_maps:
  BGP_FROM_OSPF:
    rules:
      10:
        action: permit
        match: ip address prefix-list OSPF_PREFIXES
  CONNECTED:
    rules:
      10:
        action: permit
        match: ip address prefix-list CONNECTED_PREFIXES
```


## BGP

### BGP SNMP

```yaml
quagga::bgp::agentx: false
```

### BGP Router

```yaml
quagga::bgp::router:
  as_number: 65000
  default_ipv4_unicast: false
  import_check: true
  router_id: 10.0.0.1
  keepalive: 3
  holdtime: 9
```

### BGP Address Families

```yaml
quagga::bgp::address_families:
  ipv4_unicast:
    aggregate_address:
      - 1.1.1.0/24 summary-only
      - 1.1.2.0/24 summary-only
    maximum_ebgp_paths: 2
    maximum_ibgp_paths: 10
    networks:
      - 1.1.1.0/23
      - 1.1.3.0/24
  ipv4_multicast:
    networks:
      - 230.0.0.0/8
      - 231.0.0.0/8
  ipv6_unicast:
    aggregate_address:
      - 2001:db8:0:2::/64
      - 2001:db8:0:3::/64
    networks:
      - 2001:db8::/64
      - 2001:db8:0:1::/64
      - 2001:db8:0:2::/63
```

### BGP Peers

```yaml
quagga::bgp::peers:
  CLIENTS:
    passive: true
    address_families:
      ipv4_unicast:
        activate: true
        default_originate: true
  INTERNAL:
    remote_as: 65000
    password: QWRF$345!#@$
    update_source: 10.0.0.1
    address_families:
      ipv4_unicast:
        activate: true
        next_hop_self: true
  10.0.0.2:
    peer_group: INTERNAL
    address_families:
      ipv4_unicast:
        peer_group: INTERNAL
  10.0.0.3:
    peer_group: INTERNAL
    address_families:
      ipv4_unicast:
        peer_group: INTERNAL
  10.0.0.10:
    peer_group: INTERNAL
    address_families:
      ipv4_multicast:
        activate: true
  172.16.0.2:
    peer_group: CLIENTS
    remote_as: 65001
    address_families:
      ipv4_unicast:
        peer_group: CLIENTS

```

### BGP AS-Paths

```yaml
quagga::bgp::as_paths:
  FROM_AS100:
    rules:
      - permit _100$
```

### BGP Community Lists

```yaml
quagga::bgp::community_lists:
  100:
    rules:
      - permit 65000:101
      - permit 65000:102
      - permit 65000:103
  200:
    rules:
      - permit 65000:201
      - permit 65000:202
```

## OSPF

### OSPF SNMP

```yaml
quagga::ospf::agentx: false
```

### OSPF Router

```yaml
quagga::ospf::router:
  distribute_list:
    - ACCESS_LIST out kernel
    - ACCESS_LIST out isis
  log_adjacency_changes: true
  opaque: false
  passive_interfaces:
    - eth0
    - eth1
  redistribute:
    - connected route-map CONNECTED
  rfc1583: false
  router_id: 10.0.0.1
```

### OSPF Areas

```yaml
quagga::ospf::areas:
  0.0.0.0:
    networks:
      - 172.16.0.0/24
      - 192.168.0.0/24
    ranges:
      1.1.1.1/32:
        substitute: 1.1.1.0/24
  0.0.0.1:
    networks:
      - 172.16.1.0/24
      - 192.168.1.0/24
    stub: true
```

### OSPF Interfaces

```yaml
quagga::ospf::interfaces:
  eth0:
    dead_interval: 8
    hello_interval: 2
    mtu_ignore: true
    priority: 100
```

## PIM

### PIM SNMP

```yaml
quagga::pim::agentx: false
```

### PIM Router

```yaml
quagga::pim::router:
  ip_multicast_routing: true
```

### PIM Interfaces

```yaml
quagga::pim::interfaces:
  eth0:
    igmp: true
    multicast: true
    pim_ssm: true
```
