class quagga::zebra (
  String $config_file,
  Boolean $config_file_manage,
  String $service_name,
  Boolean $service_enable,
  Boolean $service_manage,
  Enum['running', 'stopped'] $service_ensure,
  String $service_opts,
  Hash $routes,
) {
  include quagga::zebra::config
  include quagga::zebra::service

  $routes.each | $destination, $options | {
    quagga_static_route { $destination:
      * => $options
    }
  }
}
