[![Build Status](https://travis-ci.org/bibigon812/bibigon812-quagga.svg?branch=master)](https://travis-ci.org/bibigon812/bibigon812-quagga)

## Overview

This module provides management of network protocols without restarting
services. All resources make changes to the configuration of services using
commands, as if you are doing this through the CLI.

## Quick start

Include with default parameters:

```puppet
include quagga
```
## Setup Quagga

### System Settings

These settings are used by default:

```yaml
quagga::default_owner: quagga
quagga::default_group: quagga
quagga::default_mode: '0600'
quagga::default_content: "hostname %{::facts.networking.fqdn}\n"
quagga::config_dir: /etc/quagga
quagga::service_file_manage: true
quagga::packages:
  quagga:
    ensure: present
```

### Service Settings

These settings are used by default:

```yaml
quagga::bgp::config_file: "%{lookup('quagga::config_dir')}/bgpd.conf"
quagga::bgp::config_file_manage: true
quagga::bgp::service_name: bgpd
quagga::bgp::service_enable: true
quagga::bgp::service_manage: true
quagga::bgp::service_ensure: running
quagga::bgp::service_opts: -P 0

quagga::ospf::config_file: "%{lookup('quagga::config_dir')}/ospfd.conf"
quagga::ospf::config_file_manage: true
quagga::ospf::service_name: ospfd
quagga::ospf::service_enable: true
quagga::ospf::service_manage: true
quagga::ospf::service_ensure: running
quagga::ospf::service_opts: -P 0

quagga::zebra::config_file: "%{lookup('quagga::config_dir')}/zebra.conf"
quagga::zebra::config_file_manage: true
quagga::zebra::service_name: zebra
quagga::zebra::service_enable: true
quagga::zebra::service_manage: true
quagga::zebra::service_ensure: running
quagga::zebra::service_opts: -P 0

quagga::pim::config_file: "%{lookup('quagga::config_dir')}/pimd.conf"
quagga::pim::config_file_manage: true
quagga::pim::service_name: pimd
quagga::pim::service_enable: true
quagga::pim::service_manage: true
quagga::pim::service_ensure: running
quagga::pim::service_opts: -P 0
```

## Configure Services

### Global Options

```yaml
quagga::global_opts:
  ip_forwarding: true
  ipv6_forwarding: true
```

### Interfaces

```yaml
quagga::interfaces:
  eth0:
    ip_address:
      - 10.0.0.1/24
  lo:
    ip_address:
      - 10.255.255.1/32
      - 172.16.255.1/32

quagga::ospf::interfaces:
  eth0:
    dead_interval: 8
    hello_interval: 2
    mtu_ignore: true
    priority: 100

quagga::pim::interfaces:
  eth0:
    igmp: true
    multicast: true
    pim_ssm: true
```

### BGP

```yaml
quagga::bgp::router:
  as_number: 65000
  default_ipv4_unicast: false
  import_check: true
  router_id: 10.0.0.1
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

### OSPF

```yaml
quagga::ospf::router:
  log_adjacency_changes: true
  opaque: false
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
  0.0.0.1:
    networks:
      - 172.16.1.0/24
      - 192.168.1.0/24
    stub: true
```

### As-path Lists

```yaml
quagga::bgp::as_paths:
  FROM_AS100:
    rules:
      - permit _100$
```

### Community Lists

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

### Prefix Lists

```yaml
quagga::prefix_lists:
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
quagga::route_maps:
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

## Reference

### Classes

#### quagga

- `global_opts`: Quagga global options. See the type `quagga_global`.
- `interfaces`: Quagga interfacec options. See the type `quagga_interface`.
- `prefix_lists`: Quagga prefix-list options. See the type `quagga_prefix_list`.
- `route_maps`: Quagga route-map options. See the type `quagga_rotue_map`.
- `default_owner`: overrides the default owner of Quagga configuration files in the file system.  Default value: `quagga`.
- `default_group`: overrides the default group of Quagga configuration files in the file system. Default value: `quagga`.
- `default_mode`: overrides the default mode of Quagga configuration files in the system. Default value: `0600`.
- `default_content`: overrides the initial content of quagga configuration files.
- `service_file`: overrides the default path of the Quagga system configuration file in the file system.
- `service_file_manage`: enable management of the service file. Default value: `true`.
- `packages`: Quagga package options.

#### quagga::bgp

- `config_file`: configuration file if the BGP service.
- `config_file_manage`: enable management of the BGP service setting file.
- `service_name`: the name of the BGP service.
- `service_enable`: enable the BGP service.
- `service_manage`: enable management of the BGP service.
- `service_ensure`: the state of the BGP Service.
- `service_opts`: service start options.
- `router`: BGP router options. See the type `quagga_bgp_router`.
- `peers`: BGP peer options. See the type `quagga_bgp_peer`.
- `as_paths`: as-path options. See the type `quagga_bgp_as_path`.
- `community_lists`: community-list options. See the type `quagga_bgp_community_list`.
- `address_families`: BGP address-family options. See the type `quagga_bgp_address_family`.

#### quagga::ospf

- `config_file`: configuration file if the OSPF service.
- `config_file_manage`: enable management of the OSPF service setting file.
- `service_name`: the name of the OSPF service.
- `service_enable`: enable the OSPF service.
- `service_manage`: enable management of the OSPF service.
- `service_ensure`: the state of the OSPF Service.
- `service_opts`: service start options.
- `router`: OSPF router options. See the type `quagga_ospf_router`.
- `areas`: OSPF area options. See the type `quagga_ospf_area`.
- `interfaces`: OSPF parameters of interfaces. See the type `quagga_ospf_interface`.

#### quagga::pim

- `config_file`: configuration file if the PIM service.
- `config_file_manage`: enable management of the PIM service setting file.
- `service_name`: the name of the PIM service.
- `service_enable`: enable the PIM service.
- `service_manage`: enable management of the PIM service.
- `service_ensure`: the state of the PIM Service.
- `service_opts`: service start options.
- `router`: PIM router options. See the type `quagga_ospf_pim`.
- `interfaces`: OSPF parameters of interfaces. See the type `quagga_pim_interface`.

#### quagga::zebra

- `config_file`: configuration file if the Zebra service.
- `config_file_manage`: enable management of the Zebra service setting file.
- `service_name`: the name of the Zebra service.
- `service_enable`: enable the Zebra service.
- `service_manage`: enable management of the Zebra service.
- `service_ensure`: the state of the Zebra Service.
- `service_opts`: service start options.

### Defines

#### quagga::bgp::peer

See the type `quagga_bgp_peer`

### Types

#### quagga_as_path

```puppet
quagga_as_path { 'TEST_AS_PATH':
    ensure => present,
    rules => [
        'permit _100$',
        'permit _100_',
    ],
}
```

- `name`: the name of the as-path access-list.
- `ensure`: manage the state of this as-path list: `absent`, `present`.
- `rules`: the list of rules.

#### quagga_bgp_router

```puppet
quagga_bgp_router { 'bgp':
    ensure                   => present,
    as_number                => 65000,
    import_check             => true,
    default_ipv4_unicast     => false,
    default_local_preference => 100,
    redistribute             => [ 'ospf route-map BGP_FROM_OSPF', ],
    router_id                => '192.168.1.1',
}
```

- `name`: the instance name.
- `ensure`: manage the state of this BGP router: `absent`, `present`.
- `as_number`: the number of the AS.
- `import_check`: check BGP network route exists in IGP. Default value: `false`.
- `default_ipv4_unicast`: activate ipv4-unicast for a peer by default. Default value: `false`.
- `default_local_preference`: default local preference. Default value: `100`.
- `redistribute`: redistribute information from another routing protocol.
- `router_id`: override configured router identifier.

#### quagga_bgp_address_family

```puppet
quagga_bgp_address_family { 'ipv4_unicast':
  aggregate_address  => '192.168.0.0/24 summary-only',
  maximum_ebgp_paths => 2,
  maximum_ibgp_paths => 2,
  networks           => ['192.168.0.0/24', '172.16.0.0/24',],
}

quagga_bgp_address_family { 'ipv4_multicast':
  aggregate_address => '230.0.0.0/8 summary-only',
  networks          => [ '230.0.0.0/8', '231.0.0.0/8', ],
}
```

- `name`: the address family.
- `aggregate_address`: configure BGP aggregate entries.
- `maximum_ebgp_paths`: forward packets over multiple ebgp paths.
- `maximum_ibgp_paths`: forward packets over multiple ibgp paths.
- `networks`: specify a network to announce via BGP.

#### quagga_bgp_peer

```puppet
quagga_bgp_peer { '192.168.1.1':
    ensure     => present,
    peer_group => 'internal_peers',
}

quagga_bgp_peer { 'internal_peers':
    ensure     => present,
    local_as   => 65000,
    peer_group => true,
    remote_as  => 65000,
}
```

- `name`: a neighbor IP address or a peer-group name.
- `ensure`: manage the state of this BGP neighbor: `absent`, `present`: Default value: `present`.
- `local_as`: specify a local-as number.
- `passive`: don't send open messages to this neighbor. Default value: `false`.
- `peer_group`: member of the peer-group.
- `remote_as`: specify a BGP neighbor AS.
- `shutdown`: administratively shut down this neighbor. Default value: `false`.
- `update_source`: source of routing updates.

#### quagga_bgp_peer_address_family

```puppet
quagga_bgp_peer_address_family { '192.168.0.2 ipv4_unicast':
    peer_group             => PEER_GROUP,
    activate               => true,
    allow_as_in            => 1,
    default_originate      => true,
    maximum_prefix         => 500000,
    next_hop_self          => true,
    prefix_list_in         => PREFIX_LIST,
    prefix_list_out        => PREFIX_LIST,
    remove_private_as      => true,
    route_map_export       => ROUTE_MAP,
    route_map_import       => ROUTE_MAP,
    route_map_in           => ROUTE_MAP,
    route_map_out          => ROUTE_MAP,
    route_reflector_client => false,
    route_server_client    => false,
    send_community         => 'both',
}
```

- `name`: contains peer and address family names separated by space.
- `ensure`: manage the state of this BGP neighbor: `absent`, `present`: Default value: `present`.
- `activate`: enable the Address Family for this Neighbor. Default value: `true`.
- `allow_as_in`: accept as-path with my AS present in it.
- `default_originate`: originate default route to this neighbor. Default value: `false`.
- `next_hop_self`: disable the next hop calculation for this neighbor. Default value: `false`.
- `peer_group`: member of the peer-group.
- `prefix_list_in`: filter updates from this neighbor.
- `prefix_list_out`: filter updates to this neighbor.
- `route_map_export`: apply map to routes coming from a Route-Server client.
- `route_map_import`: apply map to routes going into a Route-Server client's table.
- `route_map_in`: apply map to incoming routes.
- `route_map_out`: apply map to outbound routes.
- `route_reflector_client`: configure a neighbor as Route Reflector client. Default value: `false`.
- `route_server_client`: configure a neighbor as Route Server client. Default value: `false`.

#### quagga_community_list

```puppet
quagga_community_list { '100':
    ensure => present,
    rules  => [
        'permit 65000:50952',
        'permit 65000:31500',
    ],
}
```

- `name`: community list number.
- `ensure`: manage the state of this community list: `absent`, `present`: Default value: `present`.
- `rules`: the list of rules.

#### quagga_global

```puppet
quagga_global { 'router-1.sandbox.local':
    password                    => 'password',
    enable_password             => 'enable_password',
    ip_forwarding               => true,
    ipv6_forwarding             => true,
    line_vty                    => true,
    service_password_encryption => true,
}
```

- `name`: router instance name.
- `hostname`: router hostname. Default value: `name`.
- `password`: set password for vty interface. If there is no password, a vty won’t accept connections.
- `enable_password`: set enable password.
- `ip_forwarding`: enable IP forwarding. Default value: `false`.
- `ipv6_forwarding`: enable IPv6 forwarding. Default value: `false`.
- `line_vty`: enter vty configuration mode. Default value: `true`.
- `service_password_encryption`: encrypt passwords. Default value: `false`.

#### quagga_interface

```puppet
quagga_interface { 'eth0':
    igmp       => true,
    ip_address => [ '10.0.0.1/24', '172.16.0.1/24', ],
}
```

- `name`: the friendly name of the network interface.
- `bandwidth`: set bandwidth value of the interface in kilobits/sec.
- `description`: interface description.
- `enable`: whether the interface should be enabled or not
- `ip_address`: IP addresses. Default value: `[]`.
- `link_detect`: enable link state detection. Default value: `false`.

#### quagga_ospf_interface

```puppet
quagga_ospf_interface { 'eth0':
    auth               => 'message-digest',
    message_digest_key => '1 md5 MESSAGEDIGEST',
    mtu_ignore         => true,
    hello_interval     => 2,
    dead_interval      => 8,
}
```

- `name`: the friendly name of the network interface.
- `auth`: interface authentication type: `absent`, `message-digest` . Default value: `absent`.
- `message_digest_key`: set OSPF authentication key to a cryptographic password: `absent`, `KEYID md5 KEY` . Default value: `absent`.
- `cost`: interface cost. Default value: `absent`.
- `dead_interval`: interval after which a neighbor is declared dead. Default value: `40`.
- `hello_interval`: time between HELLO packets. Default value: `10`.
- `mtu_ignore`: disable mtu mismatch detection. Default value: `false`.
- `network`: network type: `absent`, `broadcast`, `non-broadcast`, `point-to-multipoint`,`point-to-point` or `loopback`: Default value: `absent`.
- `priority`: router priority. Default value: `1`.
- `retransmit_interval`: time between retransmitting lost link state advertisements. Default value: `5`.
- `transmit_delay`: link state transmit delay. Default value: `1`.

#### quagga_pim_router

```puppet
quagga_pim_router { 'pim':
    ip_multicast_routing        => true
}
```

- `name`: the name must be `pim`.
- `ip_multicast_routing`: enable IP multicast forwarding. Default value: `false`.

#### quagga_pim_interface

```puppet
quagga_interface { 'eth0':
    igmp      => true,
    multicast => true,
    pim_ssm   => true,
}
```

- `name`: the friendly name of the network interface.
- `igmp`: enable IGMP. Default value: `false`.
- `igmp_query_interval`: IGMP query interval. Default value: `125`.
- `igmp_query_max_response_time_dsec`: IGMP maximum query response time in deciseconds. Default value: `100`.
- `multicast`: enable multicast flag for the interface. Default value: `false`.
- `pim_ssm`: enable PIM SSM operation. Default value: `false`.


#### quagga_ospf_router

```puppet
quagga_ospf_router { 'ospf':
    ensure       => present,
    abr_type     => 'cisco',
    opaque       => true,
    redistribute => [ 'connected', 'static route-map STATIC', ],
    rfc1583      => true,
    router_id    => '10.0.0.1',
}
```

- `name`: the name must be `ospf`.
- `ensure`: manage the state of this OSPF router: `absent`, `present`: Default value: `present`.
- `abr_type`: set OSPF ABR type. Default value: `cisco`.
- `log_adjacency_changes`: log changes in adjacency. Default value: `false`.
- `opaque`: enable the Opaque-LSA capability (rfc2370). Default value: `false`.
- `redistribute`: redistribute information from another routing protocol.
- `rfc1583`: enable the RFC1583Compatibility flag. Default value: `false`.
- `router_id`: Router-id for the OSPF process.

#### quagga_ospf_area

```puppet
quagga_ospf_area { '0.0.0.0':
    ensure  => present,
    network => [ '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16' ],
}
```

- `name`: the OSPF area.
- `ensure`: manage the state of this OSPF area: `absent`, `present`: Default value: `present`.
- `access_list_expor`: set the filter for networks announced to other areas.
- `access_list_import`: set the filter for networks from other areas announced to the specified one.
- `prefix_list_export`: filter networks sent from this area.
- `prefix_list_import`: filter networks sent to this area.
- `networks`: enable routing on an IP network. Default value: `[]`.
- `auth`: enable authentication on this area: `false`, `true`, `message-digest`: Default value: `false`.
- `stub`: . configure the area to be a stub area: `false`, `true`, `no-summary`: Default value: `false`.

#### quagga_prefix_list

The prefix_list resource is a single sequence. You can use a chain of resources
to describe comlpex prefix lists, for example:

```puppet
quagga_prefix_list {'ADVERTISED_PREFIXES 10':
    ensure => present,
    action => 'permit',
    prefix => '192.168.0.0/16',
    le     => 24,
}
quagga_prefix_list {'ADVERTISED_PREFIXES 20':
    ensure => present,
    action => 'permit',
    prefix => '172.16.0.0/12',
    le     => 24,
}
```

- `name`: name of the prefix-list and sequence number.
- `ensure`: manage the state of this prefix list: `absent`, `present`: Default value: `present`.
- `action`: action can be `permit` or `deny`.
- `ge`: minimum prefix length to be matched.
- `le`: maximum prefix length to be matched.
- `prefix`: IP prefix `<network>/<length>`.
- `proto`: IP protocol version: `ip`, `ipv6`: Default value: `ip`.

#### quagga_route_map

The route_map resource is a single sequence. You can use a chain of resources
to describe complex route maps, for example:

```puppet
quagga_route_map { 'bgp_out 10':
    ensure   => present,
    action   => 'permit',
    match    => 'ip address prefix-list ADVERTISED-PREFIXES'
    on_match => 'goto 65000',
}

quagga_route_map { 'bgp_out 99':
    ensure => present,
    action => 'deny',
}

quagga_route_map { 'bgp_out 65000':
    ensure   => present,
    action   => 'permit',
    match    => [
        'as-path AS_PATH_LIST',
        'community 100',
        'community 300 exact-match',
        'extcommunity 200',
        'interface eth0',
        'ip address 100',
        'ip next-hop ACCESS_LIST',
        'ip route-source prefix-list PREFIX_LIST',
        'ipv6 address IPV6_ACCESS_LIST',
        'ipv6 next-hop prefix-list IPV6_PREFIX_LIST',
        'local-preference 1000',
        'metric 0',
        'origin igp',
        'origin egp',
        'origin incomplete',
        'peer 1.1.1.1',
        'peer 100',
        'peer local',
        'probability 50',
        'tag 100',
    ],
    on_match => 'next',
    set      => [
        'aggregator as 65000',
        'as-path exclude 100 200',
        'as-path prepend 100 100 100',
        'as-path prepend last-as 5',
        'atomic-aggregate',
        'comm-list 100 delete',
        'community 0:666 additive',
        'community none',
        'forwarding address 1fff::',
        'ip next-hop 1.1.1.1',
        'ip next-hop peer-address',
        'ipv6 next-hop global 1::',
        'ipv6 next-hop local 1::',
        'ipv6 next-hop peer-address',
        'local-preference 1000',
        'metric 0',
        'metric-type type-1',
        'origin egp',
        'origin igp',
        'origin incomplete',
        'originator-id 1.1.1.1',
        'src 1.1.1.1',
        'tag 100',
        'vpn4 next-hop 1.1.1.1',
        'weight 100',
    ],
}
```

- `name`: name of the route-map and sequence number of rule.
- `action`: route map actions: `deny`,`permit`.
- `ensure`: manage the state of this route map: `absent`, `present`: Default value: `present`.
- `match`: match values from routing table. Default value: `[]`.
- `on_match`: exit policy on matches.
- `set`: set values in destination routing protocol. Default value: `[]`.
