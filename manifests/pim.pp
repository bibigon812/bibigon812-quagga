class quagga::pim (
  String $config_file,
  Boolean $config_file_manage,
  String $service_name,
  Boolean $service_enable,
  Boolean $service_manage,
  Enum['running', 'stopped'] $service_ensure,
  String $service_opts,
  Hash $router,
  Hash $interfaces
) {
  include quagga::pim::config
  include quagga::pim::service

  if $service_enable and $service_ensure == 'running' {
    quagga_pim_router {'pim':
      * => $router
    }

    $interfaces.each |String $interface_name, Hash $interface| {
      quagga_pim_interface {$interface_name:
        * => $interface
      }
    }
  }
}
