class quagga::route_maps (
  Hash $settings = {},

) {
  assert_private()
  # TODO:

  $real_settings = $settings.reduce({}) |$memo, $value| {
    $name = $value[0]

    $ensure = dig44($value[1], ['ensure'], 'present') ? {
      'absent' => 'absent',
      default  => 'present',
    }

    $config = dig44(value[1], ['rules'], {}).reduce({}) |$memo, $value| {
      $index = $value[0]
      merge($memo, {"${name}:${index}" => merge({ ensure => $ensure }, $value[1])})
    }

    merge($memo, $config)
  }

  unless empty($real_settings) {
    create_resources('quagga_route_map', $real_settings)
  }
}