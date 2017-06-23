class quagga::route_maps (
  Hash $settings = {},

) {
  unless empty($settings) {

    $route_maps = $settings.reduce({ }) |$memo, $value| {
      $name = $value[0]

      $ensure = dig44($value[1], ['ensure'], 'present')

      $config = dig44($value[1], ['rules'], { }).reduce({ }) |$memo, $value| {
        $index = $value[0]
        merge($memo, { "${name}:${index}" => merge({ ensure => $ensure }, $value[1]) })
      }

      merge($memo, $config)
    }

    unless empty($route_maps) {
      create_resources('quagga_route_map', $route_maps)
    }
  }
}