#
# @summary Manage the Quagga OSPF daemon
#
# @param agentx
#   Manage the AgentX integration
#
# @param config_file
#   configuration file of the OSPF service.
#
# @param config_file_manage
#   Manage the configuration file content
#
# @param service_ensure
#   Controls whether the service is stopped or running.
#
# @param service_name
#   the name of the OSPF service
#
# @param service_enable
#   Enable the OSPF service
#
# @param service_manage
#   Enable management of the OSPF service
#
# @param service_opts
#   Service start options
#
# @param router
#   OSPF router options.
# @see quagga_ospf_router
#
# @param areas
#   OSPF area options.
# @see quagga_ospf_area
#
#  @param interfaces
#    OSPF parameters of interfaces.
# @see quagga_ospf_interface
#
class quagga::ospf (
  Boolean $agentx,
  Boolean $config_file_manage,
  String $service_name,
  Boolean $service_enable,
  Enum['running', 'stopped'] $service_ensure,
  Boolean $service_manage,
  String $service_opts,
  Hash $interfaces,
  Hash $router,
  Hash $areas,
  Stdlib::Unixpath $config_file              = "${quagga::config_dir}/ospfd.conf",
) {
  include quagga::ospf::config
  include quagga::ospf::service

  if $service_enable and $service_ensure == 'running' {
    $agentx_ensure = $agentx ? {
      true  => 'present',
      false => 'absent'
    }

    file_line { 'ospf_agentx':
      ensure => $agentx_ensure,
      path   => $config_file,
      line   => 'agentx',
    }

    if $service_manage {
      File_line['ospf_agentx'] {
        notify => Service[$service_name]
      }
    }

    quagga_ospf_router { 'ospf':
      * => $router,
    }

    $interfaces.each |String $interface_name, Hash $interface| {
      quagga_ospf_interface { $interface_name:
        * => $interface,
      }
    }

    resources { 'quagga_ospf_area_range':
      purge => true,
    }

    $areas.each |String $area_name, Hash $area| {
      quagga::ospf::area { $area_name:
        * => $area,
      }
    }
  }
}
