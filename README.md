[![Build Status](https://travis-ci.org/bibigon812/bibigon812-quagga.svg?branch=master)](https://travis-ci.org/bibigon812/bibigon812-quagga)

## Overview

This module provides management of network protocols, such as BGP, OSPF
without restarting daemons.

## At the beginning

### quagga

Describe quagga class.

```puppet
class { 'quagga': }
```

#### Reference

  - `enable`: Manages quagga services. Default to `true`.
  - `owner`: User of quagga configuration files. Default to `quagga`.
  - `group`: Group of quagga configuration files. Default to `quagga`.
  - `mode`: Mode of quagga configuration files. Default to `600`.
  - `package_name`: Name of the quagga package. Default to `quagga`.
  - `package_ensure`: Ensure for the quagga package. Default to `present`.
  - `content`:  Initial content of configuration files. Default to `hostname ${::fqdn}\n`.

## The most fat

### bgp

```puppet
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
  - `import_check`: Check BGP network route exists in IGP.
  - `ipv4_unicast`: Activate ipv4-unicast for a peer by default. Default to `enabled`.
  - `maximum_paths_ebgp`: Forward packets over multiple paths ebgp. Default to `1`.
  - `maximum_paths_ibgp`: Forward packets over multiple paths ibgp. Default to `1`.
  - `router_id`: Override configured router identifier.

### bgp_neighbor

```puppet
bgp_neighbor { '65000 internal':
    ensure        => present,
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

  - `name`: It's consists of a AS number and a neighbor IP address or a peer-group name.
  - `activate`: Enable the Address Family for this Neighbor. Default to `enabled`.
  - `allow_as_in`: Accept as-path with my AS present in it.
  - `default_originate`: Originate default route to this neighbor. Default to `disabled`.
  - `local_as`: Specify a local-as number.
  - `next_hop_self`: Disable the next hop calculation for this neighbor. Default to `disabled`.
  - `passive`: Don't send open messages to this neighbor. Default to `disabled`.
  - `peer_group`: Member of the peer-group. Default to `disabled`.
  - `prefix_list_in`: Filter updates from this neighbor.
  - `prefix_list_out`: Filter updates to this neighbor.
  - `remote_as`: Specify a BGP neighbor as.
  - `route_map_export`: Apply map to routes coming from a Route-Server client.
  - `route_map_import`: Apply map to routes going into a Route-Server client's table.
  - `route_map_in`: Apply map to incoming routes.
  - `route_map_out`: Apply map to outbound routes.
  - `route_reflector_client`: Configure a neighbor as Route Reflector client. Default to `disabled`.
  - `route_server_client`: Configure a neighbor as Route Server client. Default to `disabled`.
  - `shutdown`: Administratively shut down this neighbor. Default to `disabled`.

### bgp_network

```puppet
bgp_network { '65000 192.168.1.0/24':
    ensure => present,
}
```

#### Reference

  - `name`: It's consists of a AS number and a network IP address.

### ospf

```puppet
ospf { 'ospf':
    ensure    => present,
    abr_type  => 'cisco',
    opaque    => 'disabled',
    rfc1583   => 'disabled',
    router_id => '10.0.0.1',
}
```

#### Reference

  - `name`: Name must be `ospf`.
  - `abr_type`: Set OSPF ABR type. Default to `cisco`.
  - `opaque`: Enable the Opaque-LSA capability (rfc2370). Default to `disabled`.
  - `rfc1583`: Enable the RFC1583Compatibility flag. Default to `disabled`. 
  - `router_id`: Router-id for the OSPF process.
  
### ospf_area

```puppet
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

  - `name`: OSPF area.
  - `default_cost`: Set the summary-default cost of a NSSA or stub area.
  - `access_list_expor`: Set the filter for networks announced to other areas.
  - `access_list_import`: Set the filter for networks from other areas announced to the specified one.
  - `prefix_list_export`: Filter networks sent from this area.
  - `prefix_list_import`: Filter networks sent to this area.
  - `networks`: Enable routing on an IP network.
  - `stub`: Configure OSPF area as stub: `enabled`, `disabled` or `no_summary`. Default to `disabled`.
  
### ospf_interface

```puppet
ospf_interface { 'eth0':
    mtu_ignore     => 'enabled',
    hello_interval => 2,
    dead_interval  => 8,
}
```

#### Reference

  - `name`: The friendly name of the network interface.
  - `cost`: Interface cos. Default to `10`.
  - `dead_interval`: Interval after which a neighbor is declared dead. Default to `40`. 
  - `hello_interval`: Time between HELLO packets. Default to `10`.
  - `mtu_ignore`: Disable mtu mismatch detection. Default to `disabled`.
  - `network`: Network type: `broadcast`, `non_broadcast`, `point_to_point` or `loopback`. Default to `broadcast`.
  - `priority`: Router priority. Default to `1`.
  - `retransmit_interval`: Time between retransmitting lost link state advertisements. Default to `5`.
  - `transmit_delay`: Link state transmit delay. Default to `1`.

### redistribution

```puppet
redistribution { 'ospf::connected':
    metric      => 100,
    metric_type => 2,
    route_map   => 'CONNECTED',
}

redistribution { 'bgp:65000:ospf':
    metric    => 100,
    route_map => 'WORD',
}
```

#### Reference

  - `name`: The name contains the main protocol, the id and the protocol for redistribution.
  - `metric`: Metric for redistributed routes.
  - `metric_type`: OSPF exterior metric type for redistributed routes.
  - `route_map`: Route map reference.

### route_map

The route_map resource is a single sequence. You can use a chain of resources
to describe complex route maps, for example:

```puppet
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

  - `name`: Name of the route-map, action and sequence number of rule.
  - `match`: Match values from routing table.
  - `on_match`: Exit policy on matches.
  - `set`: Set values in destination routing protocol.


### prefix_list

The prefix_list resource is a single sequence. You can use a chain of resources
to describe compex prefix lists, for example:

```puppet
prefix_list {'ADVERTISED_PREFIXES:10':
    ensure => present,
    action => 'permit',
    prefix => '192.168.0.0/16',
    le     => 24,
}
prefix_list {'ADVERTISED_PREFIXES:20':
    ensure => present,
    action => 'permit',
    prefix => '172.16.0.0/12',
    le     => 24,
}
```

#### Reference

  - `name`: Name of the prefix-list and sequence number of rule: `name:sequence`.
  - `action`: Action can be `permit` or `deny`.
  - `ge`: Minimum prefix length to be matched.
  - `le`: Maximum prefix length to be matched.
  - `prefix`: IP prefix `<network>/<length>`.
  - `proto`: IP protocol version: `ip`, `ipv6`. Default to `ip`.

### community_list

```puppet
community_list { '100':
    rules  => [
        permit => 65000:50952,
        permit => 65000:31500,
    ],
}
```

#### Reference

  - `name`: Community list number.
  - `rules`: A rule of the community list `{ action => community }`.    

### as_path

```puppet
as_path { 'TEST_AS_PATH':
    ensure => present,
    rules => [
        permit => '_100$',
        permit => '_100_',
    ],
}
```

#### Reference

  - `name`: The name of the as-path access-list.
  - `rules`: A rule of the as-path access-list `{ action => regex }`.

## Hiera

If Hierea is in your mind you can use something like this.

### bgp proxy

```yaml
---
site::profiles::bgp:
  65000:
    import_check: enabled
    ipv4_unicast: disabled
    router_id: 172.16.32.103
    neighbor:
      INTERNAL:
        activate: enabled
        allow_as_in: 1
        next_hop_self: enabled
        peer_group: enabled
        remote_as: 197888
      172.16.32.105:
        peer_group: INTERNAL
    network:
      - 172.16.32.0/24
      - 192.168.0.0/24
```

```puppet
class site::profiles::bgp {
  $bgp = hiera_hash('site::profiles::bgp', {}).reduce({}) |$bgp, $bgp_config| {
    $as = $bgp_config[0]
    $bgp_configs = $bgp_config[1].reduce({}) |$params, $param| {
      if $param[0] == 'network' {
        if $param[1] {
          any2array($param[1]).each |$network| {
            create_resources('bgp_network', { "${as} ${network}" => { ensure => present, } })
          }
        }
        $hash = {}
      } elsif $param[0] == 'neighbor' {
        if $param[1] {
          $param[1].each |$neighbor, $neighbor_config| {
            create_resources('bgp_neighbor', { "${as} ${neighbor}" => $neighbor_config })
          }
        }
        $hash = {}
      } else {
        $hash = { $param[0] => $param[1] }
      }
      merge($params, $hash)
    }
    merge($bgp, { $as => $bgp_configs })
  }
  create_resources('bgp', $bgp)
}
```

### ospf proxy

```yaml
---
site::profiles::ospf:
  area:
    0.0.0.0:
      networks:
        - 10.0.10.0/24
        - 10.0.100.0/24
    0.0.0.10:
      stub: enabled
      networks:
        - 192.168.1.0/24
        - 10.0.0.0/24
        - 172.16.100.0/24
  redistribute:
    - bgp:
        metric: 100
        route_map: ROUTE_MAP
    - connected

site::profiles::interface:
  eth1:
    ip:
      ospf:
        dead_interval: 8
        hello_interval: 2
        mtu_ignore: enabled
        network: broadcast
        priority: 100
        retransmit_interval: 4
        transmit_delay: 1
```

```puppet
class site::profiles::ospf {
  $config = hiera_hash('site::profiles::ospf', {})

  unless empty($config) {

    $ospf = { 'ospf' => delete(delete($config, 'redistribute'), 'area') }

    $ospf_areas = dig($config, ['area'], {}).reduce({}) |$memo, $value| {
      $area = $value[0]
      $options = $value[1].reduce({}) |$memo, $value| {
        if $value[0] == 'networks' {
          $options = sort($value[1])
        } else {
          $options = $value[1]
        }
        merge($memo, { $value[0] => $options })
      }
      merge($memo, { $area => $options })
    }

    $redistribution = dig($config, ['redistribute'], {}).reduce({}) |$memo, $value| {
      $name = $value ? {
        Hash    => $value.keys[0],
        default => $value,
      }

      $config = $value ? {
        Hash    => $value[$name],
        default => {},
      }

      merge($memo, { "ospf::${name}" => $config })
    }

    $defaults = {
      ensure => present,
    }

    create_resources('ospf', $ospf, $defaults)
    create_resources('redistribution', $redistribution)
    create_resources('ospf_area', $ospf_areas)
  }

  $ospf_interface = hiera_hash('site::profiles::interface', {}).reduce({}) |$memo, $iface| {
    $iface_name = $iface[0]
    $ospf_interface = try_get_value($iface[1], 'ip/ospf')
    if $ospf_interface {
      merge($memo, { $iface_name => $ospf_interface })
    }
  }

  unless empty($ospf_interface) {
    create_resources('ospf_interface', $ospf_interface)
  }
}
```

### prefix_list proxy

```yaml
---
site::profiles::prefix_list:
  ADVERTISED_ROUTES:
    rules:
      10:
        action: 'permit'
        prefix: '192.168.0.0/24'
      1000:
        action: 'deny'
        le: 32
        prefix: '0.0.0.0/0'
```

```puppet
class site::profiles::prefix_list {
  $prefix_lists = hiera_hash('site::profiles::prefix_list', {}).reduce({}) |$memo, $value| {
    $name = $value[0]
    $ensure = $value[1]['ensure'] ? {
      'absent' => 'absent',
      default  => 'present',
    }
    $prefix_list = $value[1]['rules'].reduce({}) |$memo, $value| {
      merge($memo, {"${name}:${value[0]}" => merge({ensure => $ensure}, $value[1])})
    }
    merge($memo, $prefix_list)
  }
  create_resources('prefix_list', $prefix_lists)
}
```

### route_map proxy

```yaml
---
site::profiles::route_map:
  AS1234_in:
    1:
      action: deny
      match: ip address prefix-list AS_LOCAL
    31:
      action: permit
      match: as-path FROM_AS2345
      set: local-preference 800
    60:
      action: permit
      match: ip address prefix-list ABCD_1
      on_match: goto 100
      set: local-preference 800
    63:
      action: permit
      match: ip address prefix-list ABCD_2
      on_match: goto 100
      set: local-preference 800
    100:
      action: permit
      on_match: goto 200
      set: local-preference 200
    200:
      action: permit
      set: community 65000:1234 additive
```

```puppet
class site::profiles::route_map {
  $route_maps = hiera_hash('site::profiles::route_map', {}).reduce({}) |$route_maps, $route_map| {
    $name = $route_map[0]
    $new_route_map = $route_map[1].reduce({}) |$route_map, $sequence| {
      $index = $sequence[0]
      $action = $sequence[1]['action']
      $params = $sequence[1].reduce({}) |$params, $param| {
        $new_param = $param[1] ? {
          Array   => sort($param[1]),
          default => $param[1],
        }
        unless $param[0] == 'action' {
          merge($params, {$param[0] => $new_param})
        }
      }
      merge($route_map, {"${name}:${action}:${index}" => $params})
    }
    merge($route_maps, $new_route_map)
  }
  create_resources('route_map', $route_maps)
}
```
