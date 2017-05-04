## Overview

This module provides management of network protocols, such as BGP, OSPF, RIP,
ISIS without restarting daemons.

## Features
### Route maps
### Prefix lists
### Community lists
### BGP
### OSPF

#### Examples

```
ospf { 'ospf':
    ensure              => present,
    abr_type            => 'cisco',
    opaque              => true,
    rfc1583             => true,
    router_id           => '192.168.0.1',
}

ospf_area { '0.0.0.0':
    default_cost       => 10,
    access_list_export => 'ACCESS_LIST_EXPORT',
    access_list_import => 'ACCESS_LIST_IPMORT',
    prefix_list_export => 'PREFIX_LIST_EXPORT',
    prefix_list_import => 'PREFIX_LIST_IMPORT',
    network            => [ '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16' ],
    shortcut           => 'default',
}

ospf_area { '0.0.0.1':
    stub => true,
}

ospf_area { '0.0.0.2':
    stub => 'no-summary',
}

ospf_interface { 'eth0':
    mtu_ignore     => true,
    hello_interval => 2,
    dead_interval  => 8,
}

redistribution { 'ospf::connected':
    metric      => 100,
    metric_type => 2,
    route_map   => 'CONNECTED',
}

redistribution { 'bgp:65000:ospf':
    metric    => 100,
    route_map => WORD,
}

as_path { 'TEST_AS_PATH':
    ensure => present,
    rules => [
        permit => '_100$',
        permit => '_100_',
    ],
}

community_list { '100':
    rules  => [
        permit => 65000:50952,
        permit => 65000:31500,
    ],
}

prefix_list {'TEST_PREFIX_LIST:10':
    ensure => present,
    action => permit,
    prefix => '224.0.0.0/4',
    ge     => 8,
    le     => 24,
}

route_map {'TEST_ROUTE_MAP:permit:10':
    ensure   => present,
    match    => [
        'as-path PATH_LIST',
        'community COMMUNITY_LIST',
    ],
    on_match => 'next',
    set      => [
        'local-preference 200',
        'community none',
    ],
}
```
