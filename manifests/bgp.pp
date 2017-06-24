class quagga::bgp (
  Hash $settings = {},
) {
  unless empty($settings) {
    # Quagga supports only one bgp router
    $as = $settings.keys[0]
    $options = $settings.values[0]

    $ensure = dig44($options, ['ensure'], 'present')

    $bgp = { $as => delete($options, 'peers') }

    $bgp_peers = dig44($options, ['peers'], {}).reduce({}) |$memo, $value| {
      merge($memo, { "${as} ${value[0]}" => merge({ ensure => $ensure }, $value[1]) })
    }

    unless empty($bgp) {
      create_resources('quagga_bgp', $bgp)
    }

    unless empty($bgp_peers) {
      create_resources('quagga_bgp_peer', $bgp_peers)
    }
  }
}