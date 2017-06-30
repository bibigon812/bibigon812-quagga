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

  # Quagga only supports a single OSPF instance
  if size($router) > 1 {
    fail("Quagga only supports a single OSPF router instance in ${title}")
  }

  $router.each |String $router_name, Hash $router| {
    quagga_ospf {$router_name:
      * => $router
    }
  }

  $areas.each |String $area_name, Hash $area| {
    quagga_ospf_area {$area_name:
      * => $area
    }
  }
}
