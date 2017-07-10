class quagga (
  Hash $global_opts,
  Hash $interfaces,
  Hash $prefix_lists,
  Hash $route_maps,
  String $default_owner,
  String $default_group,
  String $default_mode,
  String $default_content,
  String $service_file,
  Boolean $service_file_manage,
  Hash $packages,
) {
  $packages.each |String $package_name, Hash $package| {
    package {$package_name:
      * => $package
    }
  }

  File {
    owner   => $default_owner,
    group   => $default_group,
    mode    => $default_mode,
    content => $default_content,
    replace => false,
    ensure  => present,
    require => Package[keys($packages)]
  }

  contain quagga::zebra
  contain quagga::bgp
  contain quagga::ospf
  contain quagga::pim

  if $service_file_manage {
    file {$service_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      replace => true,
      content => epp('quagga/quagga.sysconfig.epp')
    }
  }

  quagga_global {"${facts['networking']['fqdn']}": # lint:ignore:only_variable_string
    * => $global_opts
  }

  $interfaces.each |String $interface_name, Hash $interface| {
    quagga_interface {$interface_name:
      * => $interface
    }
  }

  resources { 'quagga_prefix_list':
    purge => true,
  }

  $prefix_lists.reduce({}) |Hash $pls, Tuple[String, Hash] $pl| {
    merge($pls, $pl[1]['rules'].reduce({}) |Hash $pl_seqs, Tuple[Integer, Hash] $pl_seq| {
      merge($pl_seqs, { "${pl[0]} ${$pl_seq[0]}" => $pl_seq[1] })
    })
  }.each |String $prefix_list_name, Hash $prefix_list| {
    quagga_prefix_list {$prefix_list_name:
      * => $prefix_list
    }
  }

  resources { 'quagga_route_map':
    purge => true,
  }

  $route_maps.reduce({}) |Hash $rms, Tuple[String, Hash] $rm| {
    merge($rms, $rm[1]['rules'].reduce({}) |Hash $rm_seqs, Tuple[Integer, Hash] $rm_seq| {
      merge($rm_seqs, { "${rm[0]} ${rm_seq[0]}" => $rm_seq[1] })
    })
  }.each |String $route_map_name, Hash $route_map| {
    quagga_route_map {$route_map_name:
      * => $route_map
    }
  }
}
