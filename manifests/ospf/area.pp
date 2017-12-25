define quagga::ospf::area (
  Enum['absent', 'present'] $ensure = 'present',
  Variant[Boolean, Enum['message-digest']] $auth = false,
  Variant[Boolean, Enum['no-summary']] $stub = false,
  Optional[String[1]] $access_list_export = undef,
  Optional[String[1]] $access_list_import = undef,
  Optional[String[1]] $prefix_list_export = undef,
  Optional[String[1]] $prefix_list_import = undef,
  Array[Stdlib::Compat::Ipv4] $networks = [],
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
      * =>  $range_opts,
    }
  }
}
