class quagga::ospf (
  Hash $settings = {},

) {
  unless empty($settings) {

    $ospf = { 'ospf' => delete(delete($settings, 'redistribute'), 'area') }

    $ospf_areas = dig44($settings, ['area'], {})

    $redistribution = dig44($config, ['redistribute'], {}).reduce({}) |$memo, $value| {
      $name = $value ? {
        Hash    => $value.keys[0],
        default => $value,
      }

      $config = $value ? {
        Hash    => $value.values[0],
        default => {},
      }

      merge($memo, { "ospf::${name}" => $config })
    }

    $defaults = {
      ensure => dig44($ospf, ['ospf', 'ensure'], 'present'),
    }

    unless empty($ospf) {
      create_resources('quagga_ospf', $ospf)
    }

    unless empty($ospf_areas) {
      create_resources('quagga_ospf_area', $ospf_areas)
    }

    unless empty($redistribution) {
      create_resources('quagga_redistribution', $redistribution)
    }
  }
}