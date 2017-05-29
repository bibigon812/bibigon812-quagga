[![Build Status](https://travis-ci.org/bibigon812/bibigon812-quagga.svg?branch=master)](https://travis-ci.org/bibigon812/bibigon812-quagga)

## Overview

This module provides management of network protocols, such as BGP, OSPF
without restarting daemons.

### Route_map

The route_map resource is a single sequence. You can use a chain of resources
to describe complex route maps, for example:

```
route_map { 'bgp_out:permit:10':
    ensure   => present,
    match    => 'ip address prefix-list ADVERTISED-PREFIXES'
    on_match => 'goto 65000',
}

route_map { 'bgp_out:deny:99':
    ensure => present,
}

route_map { 'bgp_out:permit:65000':
    ensure => present,
    set    => 'community 0:666',
}
```

#### Reference

  - `name`: Name of the route-map, action and sequence number of rule
  - `match`: Match values from routing table
  - `on_match`: Exit policy on matches
  - `set`: Set values in destination routing protocol


### Prefix lists

The prefix_list resource is a single sequence. You can use a chain of resources
to describe compex prefix lists, for example:

```
prefix_list {'ADVERTISED_PREFIXES:10':
    ensure => present,
    action => permit,
    prefix => '192.168.0.0/16',
    le     => 24,
}
prefix_list {'ADVERTISED_PREFIXES:20':
    ensure => present,
    action => permit,
    prefix => '172.16.0.0/12',
    le     => 24,
}
```

#### Reference

  - `name`: Name of the prefix-list and sequence number of rule
  - `action`: Action can be permit or deny
  - `ge`: Minimum prefix length to be matched
  - `le`: Maximum prefix length to be matched
  - `prefix`: IP prefix <network>/<length>
  - `proto`: IP protocol version

### Community lists

```
community_list { '100':
    rules  => [
        permit => 65000:50952,
        permit => 65000:31500,
    ],
}
```

#### Reference

  - `name`: Community list number
  - `rules`: Action and community { action => community }
    
### bgp

```
bgp { '65000':
    ensure             => present,
    import_check       => 'enabled',
    ipv4_unicast       => 'enabled',
    maximum_paths_ebgp => 10,
    maximum_paths_ibgp => 10,
    router_id          => '10.0.0.1',
}
```

#### Reference

  - `name`: AS number
  - `import_check`: Check BGP network route exists in IGP
  - `ipv4_unicast`: Activate ipv4-unicast for a peer by default
  - `maximum_paths_ebgp`: Forward packets over multiple paths ebgp
  - `maximum_paths_ibgp`: Forward packets over multiple paths ibgp
  - `router_id`: Override configured router identifier

### bgp_neighbor

```
bgp_neighbor { '65000 internal':
    ensure        => 'present',
    activate      => 'enabled',
    next_hop_self => 'enabled',
    peer_group    => 'enabled',
    remote_as     => 65000,
}

bgp_neighbor { '65000 10.0.0.2':
    ensure            => present,
    peer_group        => 'internal',
}

bgp_neighbor { '65000 10.0.0.3':
    ensure            => present,
    peer_group        => 'internal',
}
```

#### Reference

  - `name`: It's consists of a AS number and a neighbor IP address or a peer-group name
  - `activate`: Enable the Address Family for this Neighbor
  - `allow_as_in`: Accept as-path with my AS present in it
  - `default_originate`: Originate default route to this neighbor
  - `local_as`: Specify a local-as number
  - `next_hop_self`: Disable the next hop calculation for this neighbor
  - `passive`: Don't send open messages to this neighbor
  - `peer_group`: Member of the peer-group
  - `prefix_list_in`: Filter updates from this neighbor
  - `prefix_list_out`: Filter updates to this neighbor
  - `remote_as`: Specify a BGP neighbor as
  - `route_map_export`: Apply map to routes coming from a Route-Server client
  - `route_map_import`: Apply map to routes going into a Route-Server client's table
  - `route_map_in`: Apply map to incoming routes
  - `route_map_out`: Apply map to outbound routes
  - `route_reflector_client`: Configure a neighbor as Route Reflector client
  - `route_server_client`: Configure a neighbor as Route Server client
  - `shutdown`: Administratively shut down this neighbor

### bgp_network

```
bgp_network { '65000 192.168.1.0/24':
    ensure => present,
}
```

#### Reference

  - `name`: It's consists of a AS number and a network IP address

### ospf

```
ospf { 'ospf':
    ensure    => present,
    abr_type  => 'cisco',
    opaque    => 'disabled',
    rfc1583   => 'disabled',
    router_id => '10.0.0.1',
}
```

#### Reference

  - `name`: Name must be 'ospf'
  - `abr_type`: Set OSPF ABR type
  - `opaque`: Enable the Opaque-LSA capability (rfc2370)
  - `rfc1583`: Enable the RFC1583Compatibility flag
  - `router_id`: Router-id for the OSPF process
  
### ospf_area

```
ospf_area { '0.0.0.0':
    network => [ '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16' ],
}

ospf_area { '0.0.0.1':
    stub => 'enabled',
}

ospf_area { '0.0.0.2':
    stub => 'no-summary',
}
```

#### Reference

  - `name`: OSPF area
  - `default_cost`: Set the summary-default cost of a NSSA or stub area
  - `access_list_expor`: Set the filter for networks announced to other areas
  - `access_list_import`: Set the filter for networks from other areas announced to the specified one
  - `prefix_list_export`: Filter networks sent from this area
  - `prefix_list_import`: Filter networks sent to this area
  - `networks`: Enable routing on an IP network
  - `shortcut`: Configure the area's shortcutting mode
  - `stub`: Configure OSPF area as stub
  
### ospf_interface

```
ospf_interface { 'eth0':
    mtu_ignore     => true,
    hello_interval => 2,
    dead_interval  => 8,
}
```

#### Reference

  - `name`: The friendly name of the network interface
  - `cost`: Interface cos
  - `dead_interval`: Interval after which a neighbor is declared dead
  - `hello_interval`: Time between HELLO packets
  - `mtu_ignore`: Disable mtu mismatch detection
  - `network`: Network type
  - `priority`: Router priority
  - `retransmit_interval`: Time between retransmitting lost link state advertisements
  - `transmit_delay`: Link state transmit delay

### redistribution

```
redistribution { 'ospf::connected':
    metric      => 100,
    metric_type => 2,
    route_map   => 'CONNECTED',
}

redistribution { 'bgp:65000:ospf':
    metric    => 100,
    route_map => WORD,
}
```

#### Reference

  - `name`: The name contains the main protocol, the id and the protocol for redistribution
  - `metric`: Metric for redistributed routes
  - `metric_type`: OSPF exterior metric type for redistributed routes
  - `route_map`: Route map reference

### as_path

```
as_path { 'TEST_AS_PATH':
    ensure => present,
    rules => [
        permit => '_100$',
        permit => '_100_',
    ],
}
```

#### Reference

  - `name`: The name of the as-path access-list
  - `rules`: Rules of the as-path access-list { action => regex }