class quagga::pim (
  Boolean $agentx,
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
    $agentx_ensure = $agentx ? {
      true  => 'present',
      false => 'absent'
    }

    file_line { 'pim_agentx':
      ensure => $agentx_ensure,
      path   => $config_file,
      line   => 'agentx',
    }

    if $service_manage {
      File_line['pim_agentx'] {
        notify => Service[$service_name]
      }
    }

    quagga_pim_router { 'pim':
      * => $router,
    }

    $interfaces.each |String $interface_name, Hash $interface| {
      quagga_pim_interface { $interface_name:
        * => $interface,
      }
    }
  }
}
