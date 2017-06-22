class quagga::bgp (
  Hash $settings = {},

) {
  unless empty($settings) {

    # Quagga supports only one bgp router
    $as = $settings.keys[0]
    $options = $settings.values[0]

    $bgp = { $as => delete(delete($options, 'redistribute'), 'peers') }

    $bgp_peers = dig44($options, ['peers'], {}).reduce({}) |$memo, $value| {
      merge($memo, { "${as} ${value[0]}" => $value[1] })
    }

    $redistribution = dig44($options, ['redistribute'], {}).reduce({}) |$memo, $value| {
      $name = $value ? {
        Hash    => $value.keys[0],
        default => $value,
      }

      $config = $value ? {
        Hash    => $value.values[0],
        default => {},
      }

      merge($memo, { "bgp:${as}:${name}" => $config })
    }

    unless empty($bgp) {
      create_resources('quagga_bgp', $bgp)
    }

    unless empty($bgp_peers) {
      create_resources('quagga_bgp', $bgp_peers)
    }

    unless empty($redistribution) {
      create_resources('quagga_redistribution', $redistribution)
    }
  }
}