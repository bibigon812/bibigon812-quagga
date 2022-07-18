# @summary configure an OSPF area
#
# @param ensure
#   Manage the presence of the area
#
# @param auth
#   Enable authentication on the area
#
# @param stub
#   Configure stub or stub no-summary properties on the area
#
# @param access_list_export
#   Access list to use for OSPF area export
#
# @param access_list_import
#   Access list to use for OSPF area import
#
# @param prefix_list_export
#   Prefix list to use for OSPF area export
#
# @param prefix_list_import
#   Prefix list to use for OSPF area import
#
# @param networks
#   Networks that belong to an area. Note that with Quagga, the area must match the network for an interface _exactly_. 
#   A short mask of `/16` won't include all of the `/17s` and longer below it.
#
# @param ranges
#   Consolidate announcements to a larger block based on network ranges.
#
# @see quagga_ospf_area
# @see quagga_ospf_area_range
define quagga::ospf::area (
  Enum['absent', 'present'] $ensure = 'present',
  Variant[Boolean, Enum['message-digest']] $auth = false,
  Variant[Boolean, Enum['no-summary']] $stub = false,
  Optional[String[1]] $access_list_export = undef,
  Optional[String[1]] $access_list_import = undef,
  Optional[String[1]] $prefix_list_export = undef,
  Optional[String[1]] $prefix_list_import = undef,
  Array[String[1]] $networks = [],
  Hash $ranges = {},
) {
  quagga_ospf_area { $name:
    ensure             => $ensure,
    auth               => $auth,
    stub               => $stub,
    access_list_export => $access_list_export,
    access_list_import => $access_list_import,
    prefix_list_export => $prefix_list_export,
    prefix_list_import => $prefix_list_import,
    networks           => $networks,
  }

  $ranges.each |String[1] $range_name, Hash $range_opts| {
    quagga_ospf_area_range { "${name} ${range_name}":
      ensure => $ensure,
      *      => $range_opts,
    }
  }
}
