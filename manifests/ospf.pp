class quagga::ospf (
  Hash $settings = {},

) {
  unless empty($settings) {

    $ensure = dig44($settings, ['ensure'], 'present')

    $ospf = { 'ospf' => delete(delete($settings, 'redistribute'), 'areas') }

    $ospf_areas = dig44($settings, ['areas'], {}).reduce({}) |$memo, $value| {
      merge($memo, { $value[0] => merge({ ensure => $ensure }, $value[1]) })
    }

    $redistribution = dig44($settings, ['redistribute'], {}).reduce({}) |$memo, $value| {
      $name = $value ? {
        Hash    => $value.keys[0],
        default => $value,
      }

      $config = $value ? {
        Hash    => $value.values[0],
        default => {},
      }

      merge($memo, { "ospf::${name}" => merge({ ensure => $ensure }, $config) })
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