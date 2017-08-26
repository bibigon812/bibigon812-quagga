## [4.0.0] - 2017-08-26

### Added

- the `quagga::zebra::hostname`

### Changed

- the `quagga::prefix_lists` to the `quagga::zebra::prefix_lists`
- the `quagga::route_maps` to the `quagga::zebra::route_maps`

## [3.5.1] - 2017-08-23

### Added

- the property `distribute_list` to the resource type `quagga_ospf_router`

## [3.5.0] - 2017-08-22

### Added

- the resource type `quagga_access_list`

## [3.4.0] - 2017-08-21

### Added

- the resource type `quagga_static_route`
- the property `passive_interfaces` to the resource type `quagga_ospf_router`

## [3.3.0] - 2017-07-19

### Added

- autosubscribe methods in the quagga_bgp_peer_address_family resource type

### Updated

- docs

## [3.2.3] - 2017-07-14

### Fixed

- property validations of the `quagga_bgp_peer_address_family` resource type.

## [3.2.2] - 2017-07-13

### Fixed

- getting an AS number in resources `quagga_bgp_peer` and `quagga_bgp_peer_address_family`
- getting a BGP router-id in the resource `quagga_bgp_router`

### Removed

- retrieving the `activate` value in the provider of the resource `quagga_bgp_peer_address_family`

## [3.2.1] - 2017-07-13

### Fixed

- changing the resource `quagga_route_map`

## [3.2.0] - 2017-07-13

## Added

- the new resource type `quagga_pim_router`

## Changed

- split PIM router settings

## Removed

- the property `ip_multicast_routing` from the resource `quagga_global`

## [3.1.0] - 2017-07-12

## Added

- the `quagga_ospf_interface` resource
- the `quagga_pim_interface` resource

## Updated

- the `quagga::ospf` class
- the `quagga::pim` class

## Removed

- ospf and multicast settings from `quagga_interface` resource

## [3.0.2] - 2017-07-12

### Fixed

- applying the OSPF configuration
- the lint warning about only_variable_string
- autorequire `quagga_ospf_router` in the `quagga_ospf_area` resource

### Updated

- changelog
- docs

## [3.0.1] - 2017-07-12

### Fixed

- the lint warning when creating the resource `quagga_global`
- the creating the resource `quagga_interface`

### Updated

- docs

## [3.0.0] - 2017-07-11

### Added

- the resource `quagga_bgp_address_family`
- the resource `quagga_bgp_peer_address_family`
- the property `as_number` to the resource `quagga_bgp_router`
- the true hiera support
- many classes that are wrappers for resources `quagga_*`

### Changed

- changelog
- the resource `quagga_bgp` to `quagga_bgp_router`
- names of resources `quagga_route_map`, `quagga_prefix_list`
- the resource `quagga_bgp` to `quagga_bgp_router`
- resources `quagga_bgp_router`, `quagga_bgp_peer`

### Removed

- the resource `quagga_redistribution`

### Updated

- dependencies

## [2.0.3] - 2017-06-27

### Added

- tests

### Fixed

- a name validation of the type `quagga_bgp_peer`

### Updated

- docs
- changelog

## [2.0.2] - 2017-06-26

### Fixed

- creating the resource `quagga_bgp_peer`

### Updated

- the provider of the type `quagga_bgp_peer`

## [2.0.1] - 2017-06-26

### Fixed

- the router_id default value of the type `quagga_bgp`

## [2.0.0] - 2017-06-26

### Added

- multicast-routing by [@m4ce](https://github.com/m4ce)
- the resource `quagga_router` by [@m4ce](https://github.com/m4ce)
- the property `networks` to the resource `quagga_bgp`
- tests
- `quagga_ip` properties to the resource `quagga_system`
- the property `action` to the resource `quagga_route_map`
- wrappers for resources
- hiera support
- the property `redistribute` to the resource `quagga_ospf`
- the property `redistribute` to the resource `quagga_bgp`
- the property `default_originate` to the resource `quagga_ospf`

### Changed

- boolean values of variables to `true` or `false` in resource `bgp*`, `ospf*`
- types `ospf_interface` and `pim_interface` to `quagga_interface`
- the type `as_path` to `quagga_as_path`
- a syntax of `quagga_as_path` rules
- the type `bgp` to `quagga_bgp`
- the type `bgp_neighbor` to `quagga_bgp_peer`
- the type `bgp_network` to `quagga_bgp_network`
- the type `quagga_router` to `quagga_system`
- the type `community_list` to `quagga_community_list`
- a syntax of `quagga_community_list` rules
- the type `ospf_area` to `quagga_ospf_area`
- the type `prefix_list` to `quagga_prefix_list`
- the type `redistribution` to `quagga_redistribution`
- the type `route_map` to `quagga_route_map`
- the name of the resource `quagga_route_map`
- the property `ipaddress` to `ip_address` of the resource `quagga_interface`

### Deprecated

- the type `quagga_redistribution`

### Removed

- the method `purge` from resources `bgp*`
- the resource `quagga_bgp_network`
- properties `default_cost` and `stub` from `quagga_ospf_area`
- the resource `quagga_ip`

### Updated

- changelog
- docs

## [1.2.1] - 2017-06-07

### Added

- pim support by [@m4ce](https://github.com/m4ce)

### Fixed

- the ipv6 support of the resource `bgp_network`

## [1.1.4] - 2017-06-05

### Added

- the property `update_source` to the resource `bgp_neighbor`

### Updated

- docs

## [1.1.3] - 2017-06-01

### Fixed

- creation of the resource `ospf`

### Removed

- the property `reference_bandwidth` from the provider

### Updated

- the method `flush` of the resource `ospf`

## [1.1.2] - 2017-06-01

### Fixed

- removing of `bgp` and `bgp_neighbor` resources
- the `flush` method in the `ospf` resource

### Removed

- an unused code

### Updated

- changelog
- proxy classes

## [1.1.1] - 2017-05-31

### Fixed

- NilClass in flush methods
- errors on creating all resources

### Updated

- docs
- the ensurable method in types
- changelog

## [1.1.0] - 2017-05-31

### Fixed

- reading the activate property of the bgp_neighbor resource

### Removed

- the shortcut property of the ospf_area type

### Updated

- docs
- changelog

## [1.0.5] - 2017-05-30

### Added

- a default value of the activate property of the bgp_neighbor resource

### Fixed

- an instantiation of the bgp_neighbor resource
- removing the allow_as_in property of the bgp_neighbor resource

### Updated

- changelog

## [1.0.4] - 2017-05-30

### Fixed

- an instantiation of the ospf resource

### Removed

- a default value of the activate property of the bgp_neighbor resource

## [1.0.3] - 2017-05-30

### Fixed

- typos
- autorequires in bgp_netighbor and bgp_network resources

### Updated

- docs
- changelog

## [1.0.2] - 2017-05-30

### Added

- proxy classes to use hiera

### Updated

- changelog
- docs

### Fixed

- a control of services

## [1.0.1] - 2017-05-29

### Changed

- values of the stub property

### Updated

- changelog
- docs

## [1.0.0] - 2017-05-29

### Added

- the ospf_interface type
- the quagga provider of the ospf_interface type
- the ospf type
- the quagga provider of the ospf type
- the ospf_area type and a provider for it
- the redistribution type and a provider for it
- the as_path type and a provider for it
- the community_list type and a provider for it
- the prefix_list type and a provider for it
- the route_map type and a provider for it
- the bgp type and a provider for it
- the bgp_neighbor type and a provider for it
- the bgp_network type and a provider for it

### Updated

- changelog
- docs
