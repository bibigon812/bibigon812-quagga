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

  $prefix_lists_ = $prefix_lists.reduce({}) |$prefix_lists, $prefix_list| {

    $prefix_list_sequences = dig($prefix_list[1], 'rules')
      .reduce({}) |$prefix_list_sequences, $prefix_list_sequence| {

      merge($prefix_list_sequences,
        { "${prefix_list[0]} ${$prefix_list_sequence[0]}" => $prefix_list_sequence[1] }
      )
    }

    merge($prefix_lists, $prefix_list_sequences)
  }

  resources { 'quagga_prefix_list':
    purge => true,
  }

  $prefix_lists_.each |String $prefix_list_name, Hash $prefix_list| {
    quagga_prefix_list {$prefix_list_name:
      * => $prefix_list
    }
  }

  $route_maps_ = $route_maps.reduce({}) |$route_maps, $route_map| {

    $route_map_sequences = dig($route_map[1], 'rules')
      .reduce({}) |$route_map_sequences, $route_map_sequence| {

        merge($route_map_sequences,
          { "${route_map[0]} ${route_map_sequence[0]}" => $route_map_sequence[1] }
        )
      }

    merge($route_maps, $route_map_sequences)
  }

  resources { 'quagga_route_map':
    purge => true,
  }

  $route_maps_.each |String $route_map_name, Hash $route_map| {
    quagga_route_map {$route_map_name:
      * => $route_map
    }
  }
}
