class quagga::interfaces (
  Hash $settings = {},
) {
  create_resources('quagga_interface', $settings)
}