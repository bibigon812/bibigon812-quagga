class quagga::community_lists (
  Hash $settings = {},
) {
  unless empty($settings) {
    create_resources('quagga_community_list', $settings)
  }
}