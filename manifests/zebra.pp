class quagga::zebra (
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
  include quagga::zebra::static_route
}
