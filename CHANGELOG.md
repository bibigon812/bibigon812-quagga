## [Unreleased]
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

### Removed
- the method `purge` from resources `bgp*`
- the resource `quagga_bgp_network`
- properties `default_cost` and `stub` from `quagga_ospf_area`
- the resource `quagga_ip`

### Updated
- changelog
- docs

## [1.2.1] - 07-06-2017
### Added
- pim support by [@m4ce](https://github.com/m4ce) 

### Fixed
- the ipv6 support of the resource `bgp_network`

## [1.1.4] - 05-06-2017
### Added
- the property `update_source` to the resource `bgp_neighbor`

### Updated
- docs

## [1.1.3] - 01-06-2017
### Fixed
- creation of the resource `ospf`

### Removed
- the property `reference_bandwidth` from the provider

### Updated
- the method `flush` of the resource `ospf`

## [1.1.2] - 01-06-2017
### Fixed
- removing of `bgp` and `bgp_neighbor` resources
- the `flush` method in the `ospf` resource

### Removed
- an unused code

### Updated
- changelog
- proxy classes

## [1.1.1] - 31-05-2017
### Fixed
- NilClass in flush methods
- errors on creating all resources 

### Updated
- docs
- the ensurable method in types
- changelog

## [1.1.0] - 31-05-2017
### Fixed
- reading the activate property of the bgp_neighbor resource

### Removed
- the shortcut property of the ospf_area type

### Updated
- docs
- changelog

## [1.0.5] - 30-05-2017
### Added
- a default value of the activate property of the bgp_neighbor resource

### Fixed
- an instantiation of the bgp_neighbor resource
- removing the allow_as_in property of the bgp_neighbor resource

### Updated
- changelog

## [1.0.4] - 30-05-2017
### Fixed
- an instantiation of the ospf resource

### Removed
- a default value of the activate property of the bgp_neighbor resource

## [1.0.3] - 30-05-2017
### Fixed
- typos
- autorequires in bgp_netighbor and bgp_network resources

### Updated
- docs
- changelog

## [1.0.2] - 30-05-2017
### Added
- proxy classes to use hiera

### Updated
- changelog
- docs

### Fixed
- a control of services

## [1.0.1] - 29-05-2017
### Changed
- values of the stub property

### Updated
- changelog
- docs

## [1.0.0] - 29-05-2017
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
