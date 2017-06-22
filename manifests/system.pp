class quagga::system (
  Hash $settings = {},
) {
  unless empty($settings) {
    create_resources('quagga_system', $settings)
  }
}