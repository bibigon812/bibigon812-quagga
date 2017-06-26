[![Build Status](https://travis-ci.org/bibigon812/bibigon812-quagga.svg?branch=master)](https://travis-ci.org/bibigon812/bibigon812-quagga)

## Overview

This module provides management of network protocols without restarting
services. All resources make changes to the configuration of services using
commands, as if you are doing this through the CLI.

Currently it supports:

- BGP
- OSPF
- PIM
- Route maps
- Prefix lists
- Community lists
- AS-path lists

## Usage

```puppet
class { '::quagga':
    as_paths => {
        FROM_AS100 => {
            rules => [
                'permit _100$',
            ],
        },
    },
    bgp => {
        65000 => {
            import_check       => true,
            ipv4_unicast       => false,
            maximum_paths_ebgp => 2,
            maximum_paths_ibgp => 2,
            networks => [
                '1.1.1.0/24',
                '1.1.2.0/24',
            ],
            peers=> {
                '192.168.0.2' => {
                    peer_group => 'INTERNAL',
                },
                '192.168.0.3' => {
                    peer_group => 'INTERNAL',
                },
                INTERNAL => {
                    activate      => true,
                    next_hop_self => true,
                    peer_group    => true,
                    remote_as     => 65000,
                    update_source => '192.168.0.1',
                },
            },
            redistribute => [
                'ospf route-map BGP_FROM_OSPF',
            ],
            router_id => '10.255.255.1',
        },
    },
    community_lists => {
        100 => {
            rules => [
                'permit 65000:101',
                'permit 65000:102',
                'permit 65000:103',
            ],
        },
        200 => {
            rules => [
                'permit 65000:201',
                'permit 65000:202',
            ],
        },
    },
    global => {
        ip_forwarding               => true,
        ip_multicast_routing        => true,
        ipv6_forwarding             => true,
        service_password_encryption => true,
    },
    interfaces => {
        lo => {
            ip_address => [ 
                '10.255.255.1/32',
                '172.16.255.1/32',
            ],
        },
        eth0 => {
            igmp => true,
            ip_address => '172.16.0.1/24',
            ospf_dead_interval => 8,
            ospf_hello_interval => 2,
            ospf_mtu_ignore => true,
            pim_ssm => true,
        },
    },
    ospf => {
        areas => {
            '0.0.0.0' => {
                networks => [
                    '172.16.0.0/12',
                ],
            }
        },
        redistribute => [
            'connected route-map CONNECTED',
        ],
    },
    prefix_lists => {
        CONNECTED_NETWORKS => {
            rules => {
                500 => {
                    action => 'permit',
                    le     => 32,
                    prefix => '10.255.255.0/24',
                },
            },
        },
        OSPF_NETWORKS => {
            rules => {
                10 => {
                    action => 'permit',
                    prefix => '172.31.255.0/24',
                },
            },
        },
    },
    route_maps => {
        BGP_FROM_OSPF => {
            rules => {
                10 => {
                    action => 'permit',
                    match  => 'ip address prefix-list OSPF_NETWORKS',
                },
            },
        },
        CONNECTED => {
            rules => {
                10 => {
                    action => 'permit',
                    match  => 'ip address prefix-list CONNECTED_NETWORKS',
                },
            },
        },
    },
}
```

A full description of parameters can be found in the appropriate types.

- as_paths: [quagga_as_path](#quagga_as_path)
- bgp: [quagga_bgp](#quagga_bgp)
- bgp peers: [quagga_bgp_peer](#quagga_bgp_peer)
- community_lists: [quagga_community_list](#quagga_community_list)
- global: [quagga_global](#quagga_global)
- interfaces: [quagga_interface](#quagga_interface)
- ospf: [quagga_ospf](#quagga_ospf)
- prefix_lists: [quagga_prefix_list](#quagga_prefix_list)
- route_maps: [quagga_route_map](#quagga_route_map)

## Hiera

```yaml
quagga::global:
    ip_forwarding: true
    ip_multicast_routing: true
    ipv6_forwarding: true
    service_password_encryption: true

quagga::interfaces:
    lo:
        ip_address: 
            - 10.255.255.1/32
            - 172.16.255.1/32
    eth0:
        igmp: true
        ip_address: 172.16.0.1/24
        ospf_dead_interval: 8
        ospf_hello_interval: 2
        ospf_mtu_ignore: true
        pim_ssm: true

quagga::bgp:
    65000:
        import_check: true
        ipv4_unicast: false
        maximum_paths_ebgp: 2
        maximum_paths_ibgp: 10
        networks:
            - 1.1.1.0/24
            - 1.1.2.0/24
        router_id: 10.255.255.1
        peers:
            192.168.0.2:
                peer_group: INTERNAL
            192.168.0.3:
                peer_group: INTERNAL
            CLIENTS:
                activate: true
                default_originate: true
                passive: true
                peer_group: true
            INTERNAL:
                activate: true
                next_hop_self: true
                peer_group: true
                remote_as: 65000
                update_source: 192.168.0.1
        redistribute:
            - ospf route-map BGP_FROM_OSPF

quagga::ospf:
    areas:
        0.0.0.0:
            networks:
                - 172.16.0.0/12
    default_originate: true
    redistribute:
        - connected route-map CONNECTED
    router_id: 10.255.255.1

quagga::as_paths:
    FROM_AS100:
        rules:
            - permit _100$

quagga::community_lists:
    100:
        rules:
            - permit 65000:101
            - permit 65000:102
            - permit 65000:103
    200:
        rules:
            - permit 65000:201
            - permit 65000:202

quagga::prefix_lists:
    CONNECTED_NETWORKS:
        rules:
            500:
                action: permit
                le: 32
                prefix: 10.255.255.0/24
    OSPF_NETWORKS:
        rules:
            10:
                action: permit
                prefix: 172.31.255.0/24

quagga::route_maps:
    BGP_FROM_OSPF:
        rules:
            10:
                action: permit
                match: ip address prefix-list OSPF_NETWORKS
    CONNECTED:
        rules:
            10:
                action: permit
                match: ip address prefix-list CONNECTED_NETWORKS
```

## Reference
### Classes
#### quagga

```puppet
class { '::quagga': }
```

- `owner`. Overrides the default owner of quagga configuration files in the file system. Default value: `quagga`.
- `group`. Overrides the default group of quagga configuration files in the file system. Default value: `quagga`.
- `mode`. Overrides the default mode of quagga configuration files in the system. Default value: `600`.
- `package_name`. Overrides the default package name for the distribution you are installing to. Default value: `quagga`.
- `package_ensure`. Overrides the 'ensure' parameter during package installation. Default value: `present`.
- `content`. Overrides the initial content of quagga configuration files. Default value: `hostname ${::fqdn}\n`.
- `as_paths`. Contains as-path list settings. Default value: `{}`.
- `bgp`. Contains the setting of the bgp router. Default value: `{}`.
- `community_lists`: Contains community list settings. Default value: `{}`.
- `interfaces`: Contains network interface settings. Default value: `{}`.
- `global`: Contain global settings. Default value: `{}`.
- `ospf`. Contains the settings of the ospf router. Default value: `{}`.
- `prefix_lists`. Contains prefix list settings. Default value: `{}`.
- `route_maps`. Contains route-map settings. Default value: `{}`.

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

- `name`: The name of the as-path access-list.
- `ensure`: Manage the state of this as-path list: `absent`, `present`. Default value: `present`.
- `rules`: Array of rules `action regex`.

#### quagga_bgp

```puppet
quagga_bgp { '65000':
    ensure             => present,
    import_check       => true,
    ipv4_unicast       => true,
    maximum_paths_ebgp => 10,
    maximum_paths_ibgp => 10,
    networks           => ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16',],
    router_id          => '10.0.0.1',
}
```

- `name`: AS number
- `ensure`: Manage the state of this BGP router: `absent`, `present`. Default value: `present`.
- `import_check`: Check BGP network route exists in IGP.
- `ipv4_unicast`: Activate ipv4-unicast for a peer by default. Default value: `true`.
- `maximum_paths_ebgp`: Forward packets over multiple paths ebgp. Default value: `1`.
- `maximum_paths_ibgp`: Forward packets over multiple paths ibgp. Default value: `1`.
- `networks`: Specify a networks to announce via BGP. Default value: `[]`.
- `router_id`: Override configured router identifier.


#### quagga_bgp_peer

```puppet
quagga_bgp_peer { '65000 internal':
    ensure        => present,
    activate      => true,
    next_hop_self => true,
    peer_group    => true,
    remote_as     => 65000,
    update_source => '10.0.0.1',
}

quagga_bgp_peer { '65000 10.0.0.2':
    ensure     => present,
    peer_group => 'internal',
}

quagga_bgp_peer { '65000 10.0.0.3':
    ensure     => present,
    peer_group => 'internal',
}
```

- `name`: It's consists of a AS number and a neighbor IP address or a peer-group name.
- `ensure`: Manage the state of this BGP neighbor: `absent`, `present`. Default value: `present`.
- `activate`: Enable the Address Family for this Neighbor. Default value: `true`.
- `allow_as_in`: Accept as-path with my AS present in it.
- `default_originate`: Originate default route to this neighbor. Default value: `false`.
- `local_as`: Specify a local-as number.
- `next_hop_self`: Disable the next hop calculation for this neighbor. Default value: `false`.
- `passive`: Don't send open messages to this neighbor. Default value: `false`.
- `peer_group`: Member of the peer-group. Default value: `false`.
- `prefix_list_in`: Filter updates from this neighbor.
- `prefix_list_out`: Filter updates to this neighbor.
- `remote_as`: Specify a BGP neighbor as.
- `route_map_export`: Apply map to routes coming from a Route-Server client.
- `route_map_import`: Apply map to routes going into a Route-Server client's table.
- `route_map_in`: Apply map to incoming routes.
- `route_map_out`: Apply map to outbound routes.
- `route_reflector_client`: Configure a neighbor as Route Reflector client. Default value: `false`.
- `route_server_client`: Configure a neighbor as Route Server client. Default value: `false`.
- `shutdown`: Administratively shut down this neighbor. Default value: `false`.
- `update_source`: Source of routing updates. It can be the interface name or IP address.

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

- `name`: Community list number.
- `ensure`: Manage the state of this community list: `absent`, `present`. Default value: `present`.
- `rules`: Array of rules `action community`.

#### quagga_global

```puppet
quagga_global { 'router-1.sandbox.local':
    password                    => 'password',
    enable_password             => 'enable_password',
    ip_forwarding               => true,
    ipv6_forwarding             => true,
    ip_multicast_routing        => true,
    line_vty                    => true,
    service_password_encryption => true,
}
```

- `name`: Router instance name.
- `hostname`: Router hostname. Default value: `name`.
- `password`: Set password for vty interface. If there is no password, a vty won’t accept connections.
- `enable_password`: Set enable password.
- `ip_forwarding`: Enable IP forwarding. Default value: `false`.
- `ip_multicast_routing`: Enable IP multicast forwarding. Default value: `false`.
- `ipv6_forwarding`: Enable IPv6 forwarding. Default value: `false`.
- `line_vty`: Enter vty configuration mode. Default value: `true`.
- `service_password_encryption`: Encrypt passwords. Default value: `false`.

#### quagga_interface

```puppet
quagga_interface { 'eth0':
    igmp                => true,
    ipaddress           => [ '10.0.0.1/24', '172.16.0.1/24', ],
    multicast           => true,
    ospf_mtu_ignore     => true,
    ospf_hello_interval => 2,
    ospf_dead_interval  => 8,
    pim_ssm             => true,
}
```

- `name`: The friendly name of the network interface.
- `description`: Interface description.
- `igmp`: Enable IGMP. Default value: `false`.
- `igmp_query_interval`: IGMP query interval. Default value: `125`.
- `igmp_query_max_response_time_dsec`: IGMP maximum query response time in deciseconds. Default value: `100`.
- `ipaddress`: IP addresses. Default value: `[]`.
- `multicast`: Enable multicast flag for the interface. Default value: `false`.
- `ospf_cost`: Interface cos. Default value: `10`.
- `ospf_dead_interval`: Interval after which a neighbor is declared dead. Default value: `40`.
- `ospf_hello_interval`: Time between HELLO packets. Default value: `10`.
- `ospf_mtu_ignore`: Disable mtu mismatch detection. Default value: `false`.
- `ospf_network`: Network type: `broadcast`, `non-broadcast`, `point-to-multipoint`,`point-to-point` or `loopback`. Default value: `broadcast`.
- `ospf_priority`: Router priority. Default value: `1`.
- `ospf_retransmit_interval`: Time between retransmitting lost link state advertisements. Default value: `5`.
- `ospf_transmit_delay`: Link state transmit delay. Default value: `1`.
- `pim_ssm`: Enable PIM SSM operation. Default value: `false`.

#### quagga_ospf

```puppet
quagga_ospf { 'ospf':
    ensure    => present,
    abr_type  => 'cisco',
    opaque    => true,
    rfc1583   => true,
    router_id => '10.0.0.1',
}
```

- `name`: Name must be `ospf`.
- `ensure`: Manage the state of this OSPF router: `absent`, `present`. Default value: `present`.
- `abr_type`: Set OSPF ABR type. Default value: `cisco`.
- `log_adjacency_changes`: Log changes in adjacency. Default value: `false`.
- `opaque`: Enable the Opaque-LSA capability (rfc2370). Default value: `false`.
- `rfc1583`: Enable the RFC1583Compatibility flag. Default value: `false`.
- `router_id`: Router-id for the OSPF process.
  
#### quagga_ospf_area

```puppet
quagga_ospf_area { '0.0.0.0':
    ensure  => present,
    network => [ '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16' ],
}
```

- `name`: OSPF area.
- `ensure`: Manage the state of this OSPF area: `absent`, `present`. Default value: `present`.
- `access_list_expor`: Set the filter for networks announced to other areas.
- `access_list_import`: Set the filter for networks from other areas announced to the specified one.
- `prefix_list_export`: Filter networks sent from this area.
- `prefix_list_import`: Filter networks sent to this area.
- `networks`: Enable routing on an IP network. Default value: `[]`.

#### quagga_prefix_list

The prefix_list resource is a single sequence. You can use a chain of resources
to describe compex prefix lists, for example:

```puppet
quagga_prefix_list {'ADVERTISED_PREFIXES:10':
    ensure => present,
    action => 'permit',
    prefix => '192.168.0.0/16',
    le     => 24,
}
quagga_prefix_list {'ADVERTISED_PREFIXES:20':
    ensure => present,
    action => 'permit',
    prefix => '172.16.0.0/12',
    le     => 24,
}
```

- `name`: Name of the prefix-list and sequence number of rule: `name:sequence`.
- `ensure`: Manage the state of this prefix list: `absent`, `present`. Default value: `present`.
- `action`: Action can be `permit` or `deny`.
- `ge`: Minimum prefix length to be matched.
- `le`: Maximum prefix length to be matched.
- `prefix`: IP prefix `<network>/<length>`.
- `proto`: IP protocol version: `ip`, `ipv6`. Default value: `ip`.

#### quagga_redistribution

```puppet
quagga_redistribution { 'ospf::connected':
    ensure      => present,
    metric      => 100,
    metric_type => 2,
    route_map   => 'CONNECTED',
}

quagga_redistribution { 'bgp:65000:ospf':
    ensure    => present,
    metric    => 100,
    route_map => 'WORD',
}
```

- `name`: The name contains the main protocol, the id and the protocol for redistribution.
- `ensure`: Manage the state of this redistribution: `absent`, `present`. Default value: `present`.
- `metric`: Metric for redistributed routes.
- `metric_type`: OSPF exterior metric type for redistributed routes.
- `route_map`: Route map reference.

#### quagga_route_map

The route_map resource is a single sequence. You can use a chain of resources
to describe complex route maps, for example:

```puppet
quagga_route_map { 'bgp_out:10':
    ensure   => present,
    action   => 'permit',
    match    => 'ip address prefix-list ADVERTISED-PREFIXES'
    on_match => 'goto 65000',
}

quagga_route_map { 'bgp_out:99':
    ensure => present,
    action => 'deny',
}

quagga_route_map { 'bgp_out:65000':
    ensure => present,
    action => 'permit',
    set    => 'community 0:666',
}
```

- `name`: Name of the route-map, action and sequence number of rule.
- `action`: Route map actions: `deny`,`permit`.
- `ensure`: Manage the state of this route map: `absent`, `present`. Default value: `present`.
- `match`: Match values from routing table.
- `on_match`: Exit policy on matches.
- `set`: Set values in destination routing protocol.
