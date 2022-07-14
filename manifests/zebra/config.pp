# @api private
class quagga::zebra::config {
  if $quagga::zebra::config_file_manage {
    file { $quagga::zebra::config_file: }

    if $quagga::zebra::service_manage {
      File[$quagga::zebra::config_file] {
        notify => Service[$quagga::zebra::service_name]
      }
    }
  }
}
