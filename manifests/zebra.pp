# @summary manage the main zebra process
#
# @param agentx
#   Manage SNMP agentx processes for the main quagga zebra process
#
# @param hostname
#   Router's hostname
#
# @param global_opts
#   Global options for all daemons
#
# @param interfaces
#   Global network interface parameters
#
# @param prefix_lists
#   Create prefix lists
#
# @param route_maps
#   Create route-map entries
#
# @param routes
#   Define static routes
#
# @param access_lists
#   Define access lists to use elsewhere in quagga config
#
# @param config_file
#   The main configuration file name
#
# @param config_file_manage
#   Manage the content of the configuration file
#
# @param service_name the main zebra service name
# @param service_enable enable the service
# @param service_manage manage the service state
# @param service_ensure manage the actual service state of stopped or running
# @param service_opts service startup options
class quagga::zebra (
  Boolean $agentx,
  Boolean $config_file_manage,
  String $service_name,
  Boolean $service_enable,
  Boolean $service_manage,
  Enum['running', 'stopped'] $service_ensure,
  String $service_opts,
  String $hostname,
  Hash $global_opts,
  Hash $interfaces,
  Hash $prefix_lists,
  Hash $route_maps,
  Hash $routes,
  Hash $access_lists,
  Stdlib::Unixpath $config_file               = "${quagga::config_dir}/zebra.conf",
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
