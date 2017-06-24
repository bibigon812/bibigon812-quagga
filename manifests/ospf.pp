class quagga::ospf (
  Hash $settings = {},
) {
  $ensure = dig44($settings, ['ensure'], 'present')

  $ospf = { 'ospf' => delete($settings, 'areas') }

  $ospf_areas = dig44($settings, ['areas'], {}).reduce({}) |$memo, $value| {
    merge($memo, { $value[0] => merge({ ensure => $ensure }, $value[1]) })
  }

  unless empty($ospf) {
    create_resources('quagga_ospf', $ospf)
  }

  unless empty($ospf_areas) {
    create_resources('quagga_ospf_area', $ospf_areas)
  }
}