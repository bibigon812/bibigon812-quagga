## Overview

This module provides controls network interfaces and network protocols without
restarting. The first release will support only CentOS/RedHat 7.0.

## Features
### Route maps
### Prefix lists
### Community lists
### BGP
### OSPF

```
ospf { 'ospf':
  network => [
    - '192.168.0.0/16 area 0.0.0.0',
    - '172.16.0.0/12 area 0.0.0.0',
    - '10.0.0.0/8 area 0.0.0.0',
  ],
}

ospf_interface { 'eth0':
  mtu_ignore     => true,
  hello_interval => 2,
  dead_interval  => 8,
}
```
