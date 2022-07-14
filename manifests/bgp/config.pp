# @api private
class quagga::bgp::config {
  if $quagga::bgp::config_file_manage {
    file { $quagga::bgp::config_file: }

    if $quagga::bgp::service_manage {
      File[$quagga::bgp::config_file] {
        notify => Service[$quagga::bgp::service_name]
      }
    }
  }
}
