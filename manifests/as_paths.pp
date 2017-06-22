class quagga::as_paths (
  Hash $settings = {},
) {
  unless empty($settings) {
    create_resources('quagga_as_path', $settings)
  }
}