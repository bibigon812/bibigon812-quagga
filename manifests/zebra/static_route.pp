class quagga::zebra::static_route (
  Hash $routes = {},
) {
  $routes.each | $destination, $options | {
    quagga_static_route { $destination:
      ensure => pick($options[ensure], present),
      *      => delete($options, [ensure])
    }
  }
}
