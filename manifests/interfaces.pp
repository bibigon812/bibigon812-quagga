class quagga::interfaces (
  Hash $settings = {},
) {
  unless empty($settings) {
    create_resources('quagga_interface', $settings)
  }
}