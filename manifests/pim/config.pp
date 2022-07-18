# @api private
class quagga::pim::config {
  if $quagga::pim::config_file_manage {
    file { $quagga::pim::config_file: }

    if $quagga::pim::service_manage {
      File[$quagga::pim::config_file] {
        notify => Service[$quagga::pim::service_name]
      }
    }
  }
}
