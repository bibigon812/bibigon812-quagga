class quagga::ospf (
  String $config_file,
  Boolean $config_file_manage,
  String $service_name,
  Boolean $service_enable,
  Enum["running", "stopped"] $service_ensure,
  Boolean $service_manage,
  String $service_opts,
  Hash $router,
  Hash $areas
) {
  include quagga::ospf::config
  include quagga::ospf::service

  quagga_ospf {'ospf':
    * => $router
  }

  $areas.each |String $area_name, Hash $area| {
    quagga_ospf_area {$area_name:
      * => $area
    }
  }
}
