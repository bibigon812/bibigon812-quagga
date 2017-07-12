class quagga::ospf (
  String $config_file,
  Boolean $config_file_manage,
  String $service_name,
  Boolean $service_enable,
  Enum['running', 'stopped'] $service_ensure,
  Boolean $service_manage,
  String $service_opts,
  Hash $interfaces,
  Hash $router,
  Hash $areas,
) {
  include quagga::ospf::config
  include quagga::ospf::service

  if $service_enable and $service_ensure == 'running' {
    quagga_ospf_router {'ospf':
      * => $router
    }

    $interfaces.each |String $interface_name, Hash $interface| {
      quagga_ospf_interface {$interface_name:
        * => $interface
      }
    }

    $areas.each |String $area_name, Hash $area| {
      quagga_ospf_area {$area_name:
        * => $area
      }
    }
  }
}
