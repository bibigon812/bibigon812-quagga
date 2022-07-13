class quagga::zebra (
  Boolean $agentx,
  String $hostname,
  Hash $global_opts,
  Hash $interfaces,
  Hash $prefix_lists,
  Hash $route_maps,
  Hash $routes,
  Hash $access_lists,
  String $config_file,
  Boolean $config_file_manage,
  String $service_name,
  Boolean $service_enable,
  Boolean $service_manage,
  Enum['running', 'stopped'] $service_ensure,
  String $service_opts
) {
  include quagga::zebra::config
  include quagga::zebra::service

  if $service_enable and $service_ensure == 'running' {
    $agentx_ensure = $agentx ? {
      true  => 'present',
      false => 'absent'
    }

    file_line { 'zebra_agentx':
      ensure => $agentx_ensure,
      path   => $config_file,
      line   => 'agentx',
    }

    if $service_manage {
      File_line['zebra_agentx'] {
        notify => Service[$service_name]
      }
    }

    quagga_global { $hostname:
      * => $global_opts,
    }

    $interfaces.each |String $interface_name, Hash $interface| {
      quagga_interface { $interface_name:
        * => $interface,
      }
    }

    resources { 'quagga_prefix_list':
      purge => true,
    }

    $prefix_lists.each |String $prefix_list_name, Hash $prefix_list| {
      quagga::prefix_list { $prefix_list_name:
        * => $prefix_list,
      }
    }

    resources { 'quagga_route_map':
      purge => true,
    }

    $route_maps.each |String $route_map_name, $route_map| {
      quagga::route_map { $route_map_name:
        * => $route_map,
      }
    }

    $routes.each |String $route_title, Hash $route| {
      quagga_static_route { $route_title:
        * => $route,
      }
    }

    $access_lists.each |$access_list_name, Hash $access_list| {
      $list_name = $access_list_name ? {
        Integer => sprintf('%d', $access_list_name),
        default => $access_list_name,
      }

      quagga_access_list { $list_name:
        * => $access_list,
      }
    }
  }
}
