class quagga::prefix_lists (
  Hash $settings = {},
) {
  $prefix_lists = $settings.reduce({}) |$memo, $value| {
    $name = $value[0]

    $ensure = dig44($value[1], ['ensure'], 'present')

    $config = dig44($value[1], ['rules'], {}).reduce({}) |$memo, $value| {
      merge($memo, {"${name}:${value[0]}" => merge({ ensure => $ensure }, $value[1])})
    }

    merge($memo, $config)
  }

  unless empty($prefix_lists) {
    create_resources('quagga_prefix_list', $prefix_lists)
  }
}